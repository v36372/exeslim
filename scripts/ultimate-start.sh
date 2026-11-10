#!/bin/bash
set -euo pipefail

export HOME=/home/exedev
export USER=exedev
export PNPM_HOME="${PNPM_HOME:-/home/exedev/.local/share/pnpm}"
export PATH="/usr/local/bin:${PNPM_HOME}:/home/exedev/.local/bin:/usr/bin:/bin"
export ULTIMATE_NO_OPEN=1
export ULTIMATE_CHROMIUM_SANDBOX="${ULTIMATE_CHROMIUM_SANDBOX:-0}"

host="$(hostname -s 2>/dev/null || hostname)"
export ULTIMATE_EXE_ORIGIN="${ULTIMATE_EXE_ORIGIN:-https://${host}.exe.xyz}"
export ULTIMATE_EXE_OWNER="${ULTIMATE_EXE_OWNER:-nguyentrongtin2331@gmail.com}"

clone=/home/exedev/ultimate
project=$clone
if [[ -f /home/exedev/.ultimate/current-project ]]; then
	p="$(cat /home/exedev/.ultimate/current-project)"
	[[ -d $p ]] && project=$p
fi

cd "$project"
exec /usr/local/bin/node "$clone/bin/ultimate.ts" "$project" --port 4747 --no-open
