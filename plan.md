Status: Approved by user on 2026-04-28 for implementation handoff.
Handoff: User requested implementation handoff on 2026-04-28.


## Plan: Modular WSL Dotfiles Installer

Refactor the monolithic installer into a task-oriented shell module layout with make install as the primary entrypoint, while preserving current behavior (no Stow, idempotent linking/copying, warning-only Windows-specific optional steps). Keep install.sh only if needed as a minimal compatibility shim.

**Steps**
1. Define target structure and ownership.
Create shared shell libraries for logging, linking/deploy, and Windows path/user resolution; create executable task modules by concern (check, packages, shell, git, editorconfig, system config, oh-my-posh, winhome mount, ssh copy, host .wslconfig). Preserve strict mode and idempotency in every module.

2. Implement make-first orchestration.
Create Makefile as the primary UX with one target per domain task plus install, install-minimal, and validate. Map each target to exactly one module script where possible. Ensure install target sequence mirrors current install.sh behavior and keeps warnings/continue semantics for Windows-specific optional operations.
*depends on 1*

3. Decide install.sh compatibility behavior.
Keep install.sh only as a thin wrapper if backward compatibility is required; otherwise remove or deprecate it in docs. Since user preference is make-first and no extra entrypoint unless needed, default recommendation is a minimal wrapper that calls make install and prints migration guidance.
*depends on 2*

4. Split current logic into modules without behavior drift.
Move package install/cleanup, managed file linking rules (.bashrc copy special-case), privileged linking for /etc/wsl.conf, oh-my-posh install/theme deploy, /etc/fstab enforcement for /mnt/winhome, SSH copy+permissions, and host .wslconfig linking into dedicated modules. Keep all existing skip/warn behavior and non-destructive handling for existing non-symlink targets.
*depends on 1, 2*

5. Add validation target and checks.
Implement make validate to run functional checks aligned with repo acceptance criteria: WSL guard, symlink/copy expectations, single /mnt/winhome fstab entry, mount refresh outcome, and git precedence verification command guidance.
*depends on 2, 4*

6. Update documentation and repo guidance.
Revise README to make make install primary, document selective targets (including git-only), and include validate workflow. Update AGENTS guidance where needed so script conventions describe modular scripts plus idempotent standalone execution.
*depends on 2, 4, 5*

**Relevant files**
- c:/Users/akington/dotfiles/install.sh — convert to thin wrapper or compatibility shim behavior.
- c:/Users/akington/dotfiles/README.md — make-first usage, selective task docs, validate docs.
- c:/Users/akington/dotfiles/AGENTS.md — modular script conventions and validation alignment.
- c:/Users/akington/dotfiles/TODO.md — optionally mark installer refactor completed/updated.
- c:/Users/akington/dotfiles/.editorconfig — ensure any new shell/make paths conform to LF/CRLF rules.

**Verification**
1. Run make install in WSL and confirm successful end-to-end setup.
2. Run make git-config alone and confirm only git-related links are changed.
3. Run make windows-mount, then verify exactly one /mnt/winhome drvfs line exists in /etc/fstab and mount -a succeeds.
4. Run make ssh-setup with and without existing files to confirm skip behavior and file permissions.
5. Run make validate and confirm all checks pass.
6. Re-run make install to verify idempotency and absence of destructive overwrites.

**Decisions**
- Primary entrypoint: make install.
- Keep install.sh only if needed for compatibility; otherwise avoid dual-primary workflows.
- Granularity: one callable task per domain.
- Windows-specific optional tasks: warnings and continue.
- Add make validate target.
- No verbose or dry-run modes in this iteration.
- Explicitly no Stow.

**Further Considerations**
1. Compatibility choice at implementation time: retain a thin install.sh shim for one transition cycle, then remove in a later cleanup.
2. Validation scope: decide whether make validate should be non-destructive checks only, or also run lightweight commands that touch mount state.

