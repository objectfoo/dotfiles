
I’ll sketch a **framework-agnostic core UI API** that can be:

- Wrapped as a **web component** for BAAs  
- Mounted inside your **iframe shell app** for non‑BAAs  

Think of it as a single `PatientRecordApp` module with a clean config surface.

---

### 1. Core UI API shape

```ts
type PatientId = string;
type UserId = string;

type Permission = 'read' | 'write';

interface PatientRecordAppConfig {
  // Who is using this UI (from your system’s POV)
  userId: UserId;
  patientId: PatientId;

  // What they’re allowed to do
  permissions: Permission[];

  // Data access abstraction (you implement this per environment)
  dataProvider: PatientDataProvider;

  // Optional: visual + UX options
  theme?: 'light' | 'dark' | 'auto';
  locale?: string;
  readOnly?: boolean;

  // Callbacks for host integration
  onLoaded?: () => void;
  onError?: (error: Error) => void;
  onPatientUpdated?: (patient: Patient) => void;
  onCloseRequested?: () => void; // e.g., “Done” button
}

interface Patient {
  id: PatientId;
  name: string;
  dob: string;
  // ...only minimum necessary fields
}

interface PatientDataProvider {
  getPatient(patientId: PatientId): Promise<Patient>;
  updatePatient(patientId: PatientId, patch: Partial<Patient>): Promise<Patient>;
}
```

Core entry point:

```ts
declare function mountPatientRecordApp(
  container: HTMLElement,
  config: PatientRecordAppConfig
): { unmount: () => void };
```

That’s the heart of it.

---

### 2. How this looks in iframe mode (non‑BAA)

In your **embed shell app** at `https://app.yourdomain.com/embed/patient`:

```ts
import { mountPatientRecordApp } from './patient-record-app';
import { verifyEmbedToken } from './auth';

async function main() {
  const token = getTokenFromQueryOrPostMessage();
  const claims = await verifyEmbedToken(token);
  // claims: { userId, patientId, permissions }

  const dataProvider: PatientDataProvider = {
    async getPatient(patientId) {
      // Direct call to your internal API / DB
      return fetchJson(`/internal/patients/${patientId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
    },
    async updatePatient(patientId, patch) {
      return fetchJson(`/internal/patients/${patientId}`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` },
        body: JSON.stringify(patch)
      });
    }
  };

  const container = document.getElementById('app')!;
  mountPatientRecordApp(container, {
    userId: claims.userId,
    patientId: claims.patientId,
    permissions: claims.permissions,
    dataProvider,
    theme: 'light',
    onPatientUpdated(patient) {
      // Optional: postMessage to host if you want
      window.parent.postMessage({ type: 'patient-updated', patientId: patient.id }, '*');
    }
  });
}

main();
```

- PHI stays in your origin.  
- `dataProvider` talks to your backend only.  
- Host just sees a framed UI.

---

### 3. How this looks as a web component (BAA)

Your **SDK** might wrap the same core:

```ts
import { mountPatientRecordApp } from './patient-record-app';

class PatientRecordViewerElement extends HTMLElement {
  private root?: ShadowRoot;
  private unmount?: () => void;

  static get observedAttributes() {
    return ['patient-id', 'auth-token', 'theme'];
  }

  connectedCallback() {
    this.root = this.attachShadow({ mode: 'open' });
    this.render();
  }

  disconnectedCallback() {
    this.unmount?.();
  }

  attributeChangedCallback() {
    this.render();
  }

  private render() {
    if (!this.root) return;

    const patientId = this.getAttribute('patient-id')!;
    const authToken = this.getAttribute('auth-token')!;
    const theme = (this.getAttribute('theme') as 'light' | 'dark' | null) ?? 'light';

    // Clear previous render
    this.root.innerHTML = '';
    const container = document.createElement('div');
    this.root.appendChild(container);

    const dataProvider: PatientDataProvider = {
      async getPatient(id) {
        return fetchJson(`https://api.yourdomain.com/patients/${id}`, {
          headers: { Authorization: `Bearer ${authToken}` }
        });
      },
      async updatePatient(id, patch) {
        return fetchJson(`https://api.yourdomain.com/patients/${id}`, {
          method: 'PATCH',
          headers: { Authorization: `Bearer ${authToken}` },
          body: JSON.stringify(patch)
        });
      }
    };

    const { unmount } = mountPatientRecordApp(container, {
      userId: 'unknown-or-from-token',
      patientId,
      permissions: ['read', 'write'], // or derive from token
      dataProvider,
      theme,
      onPatientUpdated: (patient) => {
        this.dispatchEvent(
          new CustomEvent('patient-updated', { detail: { patientId: patient.id } })
        );
      }
    });

    this.unmount = unmount;
  }
}

customElements.define('patient-record-viewer', PatientRecordViewerElement);
```

Host usage:

```html
<script src="https://cdn.yourdomain.com/patient-viewer.js"></script>

<patient-record-viewer
  patient-id="P-456"
  auth-token="eyJhbGciOi..."
  theme="light"
></patient-record-viewer>
```

Same core UI, different `dataProvider` and mounting environment.

---

### 4. Why this API works well for your hybrid

- **Single mental model:** `mountPatientRecordApp(container, config)`
- **Environment-specific wiring:**
  - Iframe shell: internal tokens, internal APIs, full isolation.
  - Web component: BA token, public API, shared DOM.
- **Easy to extend:**
  - Add `mode: 'embedded' | 'full'` if you want different layouts.
  - Add `features: { allowDelete: boolean; allowNotes: boolean }` for partner-specific capabilities.

If you want, next step we can define a **JWT claim set** that maps cleanly into `PatientRecordAppConfig` (so the iframe shell is almost just “verify token → pass claims into config”).
