#!/bin/bash
# Erstellt ausschließlich eine neue VM. Vorhandene VMs bleiben unverändert.
set -euo pipefail
if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Aufruf: $0 /absoluter/pfad/hallo.img [VM-Name]" >&2
  exit 2
fi
if [[ $(uname -m) != x86_64 ]]; then
  echo 'Für diese direkte DOS-VM wird ein Intel-Mac benötigt.' >&2
  exit 2
fi
PRL='/Applications/Parallels Desktop.app/Contents/MacOS/prlctl'
IMAGE=$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve(strict=True))' "$1")
VM_NAME=${2:-FreeDOS Turbo Basic}
# Schlägt bei einem vorhandenen Namen fehl; danach wird nichts konfiguriert.
"$PRL" create "$VM_NAME" --distribution msdos --no-hdd
"$PRL" set "$VM_NAME" --bios-type legacy --cpus 1 --memsize 32
"$PRL" set "$VM_NAME" --device-set fdd0 --image "$IMAGE" --connect
"$PRL" set "$VM_NAME" --smart-mouse-optimize on --sticky-mouse on --smooth-scrolling off
"$PRL" start "$VM_NAME"
printf '%s\n' 'In das VM-Fenster klicken, um die Maus einzufangen.' 'Ctrl+Alt gibt die Maus wieder frei.'
