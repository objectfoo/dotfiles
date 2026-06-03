You’re asking the right question—because the default “just embed our data in their page with JS” is *not* safe for PII.

Short version:  
If you don’t fully trust the third party, the only modern, sane pattern is to **keep all PII on your origin** and expose it through **a tightly isolated UI surface** (usually an iframe) or **redirect flow**, backed by **OAuth2/OIDC**. Anything that gives their JavaScript direct access to raw PII is fundamentally not “secure for PII”.

---

### Core principle

If their JavaScript can read the data, they can exfiltrate it.  
So the goal is:

- **Your backend + your frontend** handle PII.
- **Their site** only:
  - embeds your UI as a black box, or
  - redirects the user to you and back.

No library, SDK, or API call from their browser can change that basic trust boundary.

---

### Pattern 1: Redirect to your site (safest, simplest)

**Flow:**

1. **User logs into third-party site.**
2. They click “Manage my profile” (or similar).
3. Third party **redirects** to your domain (e.g. `profile.yourcompany.com`) with an OAuth2/OIDC flow.
4. User authenticates/authorizes with you.
5. You show a full-page UI where they view/edit PII.
6. When done, you **redirect back** to the third party with a success status (no PII in URL).

**Why this is good:**

- **PII never lives in their DOM or JS.**
- Your cookies are **httpOnly, Secure, SameSite**, scoped to your domain.
- You can use **Authorization Code + PKCE** and short-lived tokens between your frontend and backend.
- Third party only knows “user updated their data”, not the data itself (unless you explicitly share via backend-to-backend APIs).

If you can get away with a redirect UX, this is the gold standard.

---

### Pattern 2: Cross-origin iframe widget (secure embedding)

If they really want “embedded” editing inside their page, do it as a **cross-origin iframe** that you fully control.

**Setup:**

- Third party includes:
  ```html
  <iframe
    src="https://profile.yourcompany.com/embed?client_id=XYZ"
    sandbox="allow-scripts allow-forms"
    referrerpolicy="no-referrer"
  ></iframe>
  ```
- The iframe is served from **your domain**, with **your JS only**.
- Authentication inside the iframe uses:
  - **OAuth2/OIDC Authorization Code + PKCE**, or
  - your own session cookies (httpOnly, Secure, SameSite).

**Security properties:**

- **Same-origin policy**: parent page JS cannot read iframe DOM or network responses.
- PII is rendered **only inside the iframe**, never exposed to the parent.
- You can use `sandbox` and CSP to further restrict what runs inside.

**Optional communication:**

If you need to notify the parent page (“profile updated”), use **`window.postMessage`**:

- Define a **strict origin check** on both sides.
- Only send **non-PII events** (e.g. `{ type: "profileUpdated" }`), not the actual data.

---

### Pattern 3: Backend-to-backend API with OAuth2/OIDC

If the third party is *trusted* to actually hold some PII (e.g. they’re a processor, not just a UI host), then:

- Use **OAuth2 Authorization Code + PKCE** for user consent.
- Third party backend calls your API with **scoped access tokens**:
  - `scope: profile.read`, `profile.write`, etc.
- Tokens:
  - **Short-lived access tokens** (15–60 minutes).
  - **Refresh token rotation** and revocation.
- Never put tokens in `localStorage` or `sessionStorage`; keep them:
  - in **httpOnly cookies** (for your own domain), or
  - in **server-side sessions** on the third party.

This is more about **data sharing** than embedding, but it’s the right pattern if they truly need the data server-side.

---

### What is *not* safe for PII

- **Injecting your data into their JS**:
  - JSON blobs in the page.
  - Your SDK that returns PII to their JS.
- **Tokens in browser storage**:
  - `localStorage`, `sessionStorage`, `IndexedDB` for long-lived tokens.
- **Implicit flow / ROPC**:
  - Deprecated and not acceptable for sensitive PII scenarios.

If their JS can see it, a compromised script, extension, or XSS can steal it.

---

### Concrete recommendation for your scenario

> A user logs on to a third party website, and on that website they will be able to see and edit personal data hosted on my website.

I’d design it like this:

1. **Decide trust level**:
   - If you don’t want them to ever see raw PII → **Pattern 1 or 2**.
2. **Preferred UX**:
   - If full-page redirect is acceptable → **Pattern 1 (redirect)**.
   - If they insist on inline → **Pattern 2 (cross-origin iframe widget)**.
3. **Auth between user and you**:
   - Use **OIDC Authorization Code + PKCE**.
   - Store tokens server-side or in httpOnly cookies; no JS-accessible tokens.
4. **Data sharing**:
   - Only send **events**, not PII, back to the third party (e.g. via `postMessage` or redirect parameters like `?status=updated`).

---

If you tell me:

- how much you trust the third party, and  
- whether they *must* have any copy of the PII themselves,

I can sketch a concrete flow diagram and example code (iframe + postMessage + OAuth config) tailored to your stack.
