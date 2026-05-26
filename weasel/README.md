# weasel

wsl2 backup file manager

## How To

### 1. Take a Backup (Snapshot)

To make an immutable baseline image out of a working distro (e.g., your clean `Ubuntu-24.04` workspace):

```powershell
.\weasel.ps1 Snapshot Ubuntu-24.04 node22-react-base

```

*This handles pulling your active workspace username, compiling the `.tar`, packaging the sidecar JSON configuration, and locking the file with a `.sha256` signature.*

### 2. Spin Up a New Project (The Default Menu)

Simply type the command with no arguments to pull up the text picker interface:

```powershell
.\weasel.ps1

```

It will display your template directory layout ordered by newest first:

```text
Select a base template to spawn a new environment:
  [1] node22-react-base-20260525-2140 (1.42 GB)
  [2] python-core-20260512-0915 (2.11 GB)
  [3] wsl-backup-4f8a12e3-20260420-1112 (0.85 GB)
  [q] Abort and Quit

Enter selection index: 1
Enter name for your new destination runtime environment: ecommerce-dashboard

```

Once you input your project name, it maps the integrity verification, unpacks the disk image layers into `~\WSL\ecommerce-dashboard`, writes the permanent identity overrides to `/etc/wsl.conf`, and resets execution flags so you can launch straight into your standard non-root user setup instantly.
