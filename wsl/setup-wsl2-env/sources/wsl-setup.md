# WSL2 Dev Environment Setup

Initial setup for a WSL2 Ubuntu 24.04 distro for front-end development.

**Prerequisites:** Windows Terminal and VS Code with the [WSL extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) installed.

> **Note:** Some `.wslconfig` features in this guide (e.g. `networkingMode`, `dnsTunneling`, `firewall`) require **Windows 11 22H2** or later.

**Steps overview:**
1. Configure WSL2 global settings
2. Install or update WSL (Store-backed) and set WSL2 as default
3. Install the Ubuntu distro
4. Configure the distro
5. Restart WSL
6. Update packages
7. Git Config and SSH Setup
8. Clone a repo to verify the setup
9. Backup and restore the distro

---

## 1. Global WSL2 Config

Create or edit `.wslconfig` in your Windows user directory.

**Path:** `C:\Users\<YourUsername>\.wslconfig`

Adjust `processors` and `memory` to match your machine ([search WSL2 global config tuning](https://share.google/aimode/dfaNvHrTOLkmBEgKd)).


```ini
[wsl2]
# Mirrors Windows network interfaces — avoids localhost quirks
networkingMode=mirrored
dnsTunneling=true
autoProxy=true

[experimental]
# Gradually returns unused memory to Windows
autoMemoryReclaim=gradual

# Keeps the virtual disk from growing unbounded
sparseVhd=true

firewall=true
```

---

## 2. Install or Update WSL (Store-Backed) and Enforce WSL2

Run this from PowerShell or Windows Terminal:

```pwsh
wsl --version
```

- If this returns version info, WSL is already installed. Update it:

```pwsh
wsl --update
```

- If this command is not found or WSL is missing, install the Store-backed WSL package:

```pwsh
wsl --install --web-download
```

Set WSL2 as the default and verify:

```pwsh
wsl --set-default-version 2
wsl --status
```

Confirm `Default Version: 2` appears in the status output.

---

## 3. Install the Distro

Run this from PowerShell or Windows Terminal:

```sh
wsl --install Ubuntu-24.04
```

When prompted, create a Unix username and password. Your home directory will be at `/home/<username>`.

---

## 4. Configure the Distro

Open the distro config file:

```bash
sudo nano /etc/wsl.conf
```

**Tip:** To paste from the Windows clipboard in nano:   
* **Control-Shift-V**
* **right-click** (Windows Terminal)
* **Shift+Insert** (it's oddly tricky)

Add the following:

```ini
[user]
default=<USER_NAME>

[boot]
# Enables systemd — required for Docker, databases, and other services
systemd=true

[interop]
# Keeps Windows paths in $PATH, which is needed for 'code .' to work
appendWindowsPath=true

[automount]
# Fixes file permission issues when accessing /mnt/c/
options="metadata,umask=22,fmask=11"
```

Save with **Ctrl+O**, then exit with **Ctrl+X**.

---

## 5. Restart WSL

A full shutdown is required for `wsl.conf` changes to take effect.

From inside WSL:
```bash
exit
```

From PowerShell:
```pwsh
wsl --shutdown
wsl
```

---

## 6. Update Packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y
```

Restart WSL again after a large upgrade (same steps as above).

---

## 7. Git Config and SSH Setup

Use the **WHS bootstrap script** (recommended).

### WHS Bootstrap Script

The bootstrap script automates Git config, SSH key generation, and Bitbucket registration. See the [`Initialize-Git` docs](https://proget.dev.webmd.com/endpoints/WhsInit/content/bootstrap.sh) for full details on what it configures.

From inside WSL:

```bash
bash -c "$(curl https://proget.dev.webmd.com/endpoints/WhsInit/content/bootstrap.sh)"
```

<details>
<summary>What <code>Initialize-Git</code> configures</summary>

- Sets the `HOME` environment variable so Git finds the global config consistently between elevated and non-elevated processes.
- Sets `user.name` from Active Directory (Windows) or via prompt (Mac/Linux).
- Sets `user.email` from Active Directory or via prompt.
- Sets `core.editor` to `notepad` (Windows only).
- Sets `core.autocrlf` to `false`.
- Enables Windows Credential Manager integration for secure password storage (Windows only).
- Configures Beyond Compare as the diff and merge tool (Windows only).

</details>

---

## 8. Verify — Clone a Repo

```bash
cd ~
git clone <ssh-repo-url>
```

A successful clone confirms Git, SSH, and credentials are all working.

---

## 9. Backup and Restore the Distro

Once your environment is configured, export it as a tarball. You can use this snapshot to quickly provision the same environment on another machine or recover from a bad state — without repeating the setup steps above.

### Export (backup)

From PowerShell, with WSL shut down:

```pwsh
wsl --shutdown
wsl --export Ubuntu-24.04 "C:\Backups\ubuntu-dev.tar"
```

Store the `.tar` file somewhere safe (external drive, network share, etc.).

### Import (restore)

Pick an install location for the distro's virtual disk — outside of `C:\Users` is recommended to keep it off the system drive.

```pwsh
wsl --import Ubuntu-24.04-dev "D:\WSL\Ubuntu-24.04-dev" "C:\Backups\ubuntu-dev.tar"
```

| Argument | Description |
|---|---|
| `Ubuntu-24.04-dev` | Name shown in `wsl --list` — can be anything |
| `D:\WSL\Ubuntu-24.04-dev` | Directory where the `.vhdx` disk file is stored |
| `C:\Backups\ubuntu-dev.tar` | Path to the exported tarball |

After importing, the default user resets to `root`. Restore it:

```pwsh
wsl --distribution Ubuntu-24.04-dev --user <your-username>
```

Or make it permanent by setting the default user in `/etc/wsl.conf` inside the distro:

```ini
[user]
default=<your-username>
```

Then restart:

```pwsh
wsl --shutdown
wsl --distribution Ubuntu-24.04-dev
```

