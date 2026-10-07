#!/bin/sh
# Run quirq's qqcfg on this config: qq cfg validate | generate | deliver REPO DIR | get AREA [KEY]
# It uses quirq-ai/infra-config at the commit in infra-config.commit (../infra-config, or
# $QQ_INFRA_CONFIG) and a venv in .venv-qqcfg, made from the repo's pinned Python on first use.
set -eu
root=$(pwd)   # qq runs repo commands from the repo root
pinned=$(tr -d '[:space:]' < infra-config.commit)
ic=${QQ_INFRA_CONFIG:-$root/../infra-config}

if [ $# -eq 0 ]; then
    echo "usage: qq cfg validate | generate | deliver REPO DIR | get AREA [KEY]" >&2
    exit 2
fi

if [ ! -d "$ic/.git" ]; then
    echo "qq cfg: cloning quirq-ai/infra-config into $ic" >&2
    git clone -q https://github.com/quirq-ai/infra-config "$ic"
    git -C "$ic" checkout -q "$pinned"
fi
at=$(git -C "$ic" rev-parse HEAD)
if [ "$at" != "$pinned" ]; then
    echo "qq cfg: $ic is at $at, but this config pins $pinned." >&2
    echo "  Use the pinned code:  git -C $ic checkout $pinned" >&2
    echo "  Or move the pin:      put the new commit in infra-config.commit and commit it" >&2
    exit 1
fi

venv=$root/.venv-qqcfg
if [ ! -x "$venv/bin/python" ]; then
    echo "qq cfg: creating $venv (first use)" >&2
    python3 -m venv "$venv"
    "$venv/bin/pip" install --quiet --require-hashes -r "$ic/requirements.txt"
fi

exec "$venv/bin/python" "$ic/tools/qqcfg.py" "$@" --root "$root"
