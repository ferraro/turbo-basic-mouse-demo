#!/usr/bin/env python3
"""Baut lokal eine FreeDOS-Diskette aus selbst bereitgestellten Paketen.

Es wird nichts heruntergeladen oder veröffentlicht. Ein vorhandenes Ziel
wird nie überschrieben. Die Quelldatei wird von UTF-8 nach DOS-CP437 gewandelt.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile


def ausfuehren(*argumente):
    subprocess.run(argumente, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--freedos', type=Path, required=True,
                        help='FreeDOS 1.4: FD14-FloppyEdition.zip')
    parser.add_argument('--maus', type=Path, required=True,
                        help='CuteMouse 2.0 alpha 4: cutemouse20a4.zip')
    parser.add_argument('--compiler', type=Path, required=True,
                        help='Verzeichnis mit eigenem TB.EXE und TBHELP.TBH')
    parser.add_argument('--ausgabe', type=Path, required=True,
                        help='Noch nicht vorhandene Zieldatei, z. B. bau/hallo.img')
    args = parser.parse_args()
    for werkzeug in ('mcopy', 'mmd'):
        if shutil.which(werkzeug) is None:
            parser.error(f'{werkzeug} fehlt; bitte mtools installieren.')
    if args.ausgabe.exists():
        parser.error('Das Ziel existiert bereits. Einen neuen Dateinamen wählen.')
    compilerdateien = []
    for name in ('TB.EXE', 'TBHELP.TBH'):
        funde = [p for p in args.compiler.iterdir()
                 if p.is_file() and p.name.upper() == name]
        if len(funde) != 1:
            parser.error(f'Genau eine Datei {name} im Compilerverzeichnis erwartet.')
        compilerdateien.append((name, funde[0]))
    projekt = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix='turbo-basic-') as tmp:
        arbeit = Path(tmp)
        image = arbeit / 'hallo.img'
        with zipfile.ZipFile(args.freedos) as paket:
            image.write_bytes(paket.read('144m/x86BOOT.img'))
        with zipfile.ZipFile(args.maus) as paket:
            maus = arbeit / 'CTMOUSE.EXE'
            maus.write_bytes(paket.read('ctmouse.exe'))
        # Nur ausgewählte Dateien kopieren, niemals ein ganzes fremdes Archiv.
        for name in ('FDAUTO.BAT', 'FDCONFIG.SYS'):
            text = (projekt / 'konfiguration' / name).read_text(encoding='utf-8')
            datei = arbeit / name
            datei.write_bytes(text.replace('\n', '\r\n').encode('ascii'))
            ausfuehren('mcopy', '-o', '-i', str(image), str(datei), '::')
        ausfuehren('mcopy', '-i', str(image), str(maus), '::')
        ausfuehren('mmd', '-i', str(image), '::TB')
        for name, quelle in compilerdateien:
            ausfuehren('mcopy', '-i', str(image), str(quelle), f'::TB/{name}')
        quelltext = (projekt / 'quelltext' / 'HALLO.BAS').read_text(encoding='utf-8')
        dosquelle = arbeit / 'HALLO.BAS'
        dosquelle.write_bytes(quelltext.replace('\n', '\r\n').encode('cp437'))
        ausfuehren('mcopy', '-i', str(image), str(dosquelle), '::TB/')
        exe = projekt / 'programm' / 'HALLO.EXE'
        if exe.exists():
            ausfuehren('mcopy', '-i', str(image), str(exe), '::TB/')
        args.ausgabe.parent.mkdir(parents=True, exist_ok=True)
        # Exklusives Anlegen schützt auch vor einem inzwischen angelegten Ziel.
        with args.ausgabe.open('xb') as ziel:
            ziel.write(image.read_bytes())
    print(f'Fertig: {args.ausgabe.resolve()}')
    print('Dieses Image enthält deinen Compiler und gehört nicht ins öffentliche Repo.')


if __name__ == '__main__':
    main()
