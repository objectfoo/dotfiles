#!/usr/bin/env bash
# Shared helpers for init-wsl.sh and wsl-setup.sh

log_info() {
    printf "[INFO] %s\n" "$1"
}

log_warn() {
    printf "[WARN] %s\n" "$1"
}

log_ok() {
    printf "[ OK ] %s\n" "$1"
}

require_wsl() {
    if ! grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
        log_warn "This script is intended for WSL. Exiting."
        exit 1
    fi
}

link_file() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        log_warn "Source missing, skipping link: $source"
        return
    fi

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        if [ "$(readlink "$target")" = "$source" ]; then
            log_info "Link already correct: $target"
            return
        fi

        ln -sfn "$source" "$target"
        log_ok "Updated symlink: $target -> $source"
        return
    fi

    if [ -e "$target" ]; then
        log_warn "Target exists and is not a symlink, skipping: $target"
        return
    fi

    ln -s "$source" "$target"
    log_ok "Linked: $target -> $source"
}

link_file_sudo() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        log_warn "Source missing, skipping privileged link: $source"
        return
    fi

    sudo mkdir -p "$(dirname "$target")"

    if sudo test -L "$target"; then
        if [ "$(sudo readlink "$target")" = "$source" ]; then
            log_info "Privileged link already correct: $target"
            return
        fi

        sudo ln -sfn "$source" "$target"
        log_ok "Updated privileged symlink: $target -> $source"
        return
    fi

    if sudo test -e "$target"; then
        log_warn "Privileged target exists and is not a symlink, skipping: $target"
        return
    fi

    sudo ln -s "$source" "$target"
    log_ok "Linked privileged file: $target -> $source"
}

deploy_file() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        log_warn "Source missing, skipping file deploy: $source"
        return
    fi

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        rm -f "$target"
        cp "$source" "$target"
        log_ok "Replaced symlink with managed file: $target"
        return
    fi

    if [ -e "$target" ]; then
        if cmp -s "$source" "$target"; then
            log_info "Managed file already up to date: $target"
        else
            log_warn "Target exists and differs, skipping file deploy: $target"
        fi
        return
    fi

    cp "$source" "$target"
    log_ok "Deployed managed file: $target"
}

normalize_windows_path_for_drvfs() {
    local candidate="$1"
    candidate="${candidate//$'\r'/}"
    candidate="${candidate//\\//}"
    printf "%s" "$candidate"
}

resolve_windows_home_path() {
    local candidate=""

    if command -v cmd.exe >/dev/null 2>&1; then
        candidate="$(cmd.exe /c echo %USERPROFILE% 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
    fi

    if [ -n "${candidate:-}" ]; then
        normalize_windows_path_for_drvfs "$candidate"
    fi
}
