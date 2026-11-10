REM Hallo Welt mit Maus - Borland Turbo Basic 1.0 (1987)
REM BSD-3-Clause, siehe LICENSE im Projektverzeichnis.
REM Diese Datei ist auf GitHub UTF-8. Für DOS nach CP437 wandeln.
REM
REM Worum geht es hier?
REM BASIC kennt keine Befehle wie "Maus anzeigen". Ein geladener
REM DOS-Maustreiber kennt sie aber. Wir sprechen ihn ueber INT 33h an.
REM CTMOUSE muss deshalb VOR diesem Programm gestartet worden sein.
REM
REM Was hat das mit Assembler zu tun?
REM AX, BX, CX und DX sind kleine Speicherplätze im Prozessor.
REM Sie heißen Register. AX enthält die gewünschte Mausfunktion.
REM REG 1, 3 entspricht dem Assembler-Befehl MOV AX, 3.
REM CALL INTERRUPT &H33 entspricht dem Assembler-Befehl INT 33h.
REM INT ruft hier den Maustreiber auf; danach geht BASIC weiter.
REM Wir brauchen keine eigene ASM-Datei: Turbo Basic kann das direkt.
REM
REM Achtung: Die Zahlen bezeichnen zwei verschiedene Dinge!
REM Bei REG 1, 3 bedeutet 1 "Register AX" und 3 "Maus abfragen".
REM Bei REG(3) bedeutet 3 dagegen "Register CX lesen".
REM Zuordnung: REG(1)=AX, REG(2)=BX, REG(3)=CX, REG(4)=DX.
REM &H33 ist eine Hexadezimalzahl, also 51 im Dezimalsystem.
REM Sie ist NICHT der DOS-Systemaufruf INT 21h (dezimal 33).

DEFINT A-Z
SCREEN 0
WIDTH 80
COLOR 15, 1
CLS
PRINT "Hallo Welt!"
PRINT
PRINT "Borland Turbo Basic 1.0 (1987) + FreeDOS"
PRINT "Linksklick: Hallo sagen. Esc: Programm beenden."

REM Erst prüfen, ob an der Adresse für INT 33h ein Treiber steht.
REM Die Interrupttabelle beginnt im Speichersegment 0.
REM Jeder Eintrag hat vier Bytes: zwei für Offset, zwei für Segment.
REM 51 * 4 = 204 = &HCC. Der Eintrag liegt bei &HCC bis &HCF.
REM DEF SEG = 0 lässt PEEK diese Tabelle lesen.
REM Das anschließende DEF SEG stellt das normale Datensegment wieder her.
REM Ein Eintrag ungleich null ist nur eine einfache Anwesenheitsprüfung.
REM Unser Startskript lädt deshalb vorher gezielt CTMOUSE.
DEF SEG = 0
TreiberDa = PEEK(&HCC) OR PEEK(&HCD) OR PEEK(&HCE) OR PEEK(&HCF)
DEF SEG
IF TreiberDa = 0 THEN
  PRINT "Kein Maustreiber gefunden. Bitte zuerst CTMOUSE starten."
  END
END IF

REM AX=1 bedeutet: den Mauszeiger einblenden.
REM In Assembler wäre das: MOV AX, 1 / INT 33h.
REM Funktion 0 (Treiber zurücksetzen) verwenden wir absichtlich nicht.
REM Der Treiber ist bereits geladen und initialisiert.
REG 1, 1
CALL INTERRUPT &H33

REM -1 erzwingt die erste Anzeige, auch wenn die Maus noch stillsteht.
AltX = -1
AltY = -1
AltTaste = 0
REM & macht den Zähler zu einer 32-Bit-Ganzzahl statt einer 16-Bit-Zahl.
Klicks& = 0

DO
  REM AX=3 fragt Tasten und Position ab. Es bewegt die Maus nicht.
  REM Der Treiber liefert BX=Tasten, CX=X und DX=Y zurück.
  REM Bei BX bedeutet Bit 0: linke Taste; Bit 1: rechte Taste.
  REG 1, 3
  CALL INTERRUPT &H33
  REM AND 1 blendet alle Bits außer dem für die linke Taste aus.
  Taste = REG(2) AND 1
  X = REG(3)
  Y = REG(4)

  REM Im Textmodus sind dies Treiberkoordinaten, keine Bildschirmspalten.
  REM Typischerweise entsprechen acht Einheiten einer Textzelle.
  REM Nur bei einer Änderung schreiben: Das vermeidet ständiges Flackern.
  IF X <> AltX OR Y <> AltY OR Taste <> AltTaste THEN
    REM AX=2 blendet den Zeiger kurz aus, bevor wir Text darunter ändern.
    REM Sonst könnte der Treiber beim Wegbewegen alten Text wiederherstellen.
    REG 1, 2
    CALL INTERRUPT &H33
    LOCATE 7, 1
    PRINT "Maus X:"; X; " Y:"; Y; "    "

    REM Nur den Übergang von losgelassen zu gedrückt zählen.
    REM Eine gehaltene Taste darf nicht bei jedem Schleifendurchlauf zählen.
    IF Taste = 1 AND AltTaste = 0 THEN
      INCR Klicks&
      LOCATE 9, 1
      PRINT "Hallo per Mausklick! Klicks:"; Klicks&; "   "
    END IF

    REM Genau einmal wieder einblenden für das Ausblenden oben.
    REM Der Maustreiber verwaltet dafür intern einen Zähler.
    REG 1, 1
    CALL INTERRUPT &H33
  END IF

  REM Aktuellen Zustand merken, damit wir beim nächsten Mal vergleichen können.
  AltX = X
  AltY = Y
  AltTaste = Taste
REM INKEY$ wartet nicht. Ohne Taste liefert es eine leere Zeichenkette.
REM Esc hat den Zeichencode 27. Alle anderen Tasten lassen uns weiterlaufen.
LOOP UNTIL INKEY$ = CHR$(27)

REM Zum Schluss unseren Mauszeiger ausblenden und die Textfarben zurücksetzen.
REG 1, 2
CALL INTERRUPT &H33
COLOR 7, 0
CLS
PRINT "Auf Wiedersehen!"
END
