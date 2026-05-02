---
title: WSL Setup Archive
archived_from: 03_KNOWLEDGE/wsl-setup.md
archived_on: 2026-05-01
removed_section: "7.b Option B — Manual Setup"
reason: "Section removed from primary guide to keep setup path focused on WHS bootstrap workflow."
review_notes:
  - "Main guide now presents a single recommended path for Git + SSH setup."
  - "Archived content preserved verbatim for fallback/manual reference."
---

# WSL Setup Archive

This file preserves content removed from the main WSL setup guide.

## Archived: 7.b Option B — Manual Setup

### Git Config

Create a `.gitconfig` inside WSL that delegates to your existing Windows Git config and uses Git Credential Manager for auth.

```bash
nano ~/.gitconfig
```

```ini
[include]
    path = /mnt/c/Users/<YourWindowsUsername>/.gitconfig
[credential]
    helper = "/mnt/c/Program\ Files/Git/cmd/git-credential-manager.exe"
[core]
    # Prevents Windows-style CRLF line endings from being committed
    autocrlf = input
```

### Generate an SSH Key

```bash
ssh-keygen -t ed25519 -C "you@example.com"
```

Print the public key to copy it:

```bash
cat ~/.ssh/id_ed25519.pub
```

Add it to your [Bitbucket SSH keys page](https://whsbitbucket.webmd.net/plugins/servlet/ssh/account/keys).
