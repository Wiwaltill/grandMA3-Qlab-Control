# Entwicklungsstand installieren und prüfen

Dies ist **0.1.0-dev.1**, eine Quellcode-Vorschau, kein einsatzfertiges V1-Release.
OSC, automatische Pool-Installation, Update und Cleanup sind noch gesperrt.
Das Layout existiert als vollständiger Datenplan, noch nicht als MA-Pool-Objekt.

1. Show sichern; eine Testshow in grandMA3 2.5.1.1 verwenden.
2. `python3 tools/build.py` erzeugt `dist/QLab Control.lua` und ein versioniertes
   ZIP. Das ZIP ist noch kein über den MA-Importdialog importierbares Paket.
3. In einem freien Plugin-Slot eine LuaComponent anlegen, den generierten
   Lua-Code im Editor einfügen und Plugin `QLab Control` nennen. Diese manuelle
   Entwicklungsroute muss ebenfalls auf dem Zielsystem geprüft werden.
4. `Plugin "QLab Control" "SETUP"` öffnet das native Setup-Fenster.
   Port, OSC-Ausgang, Grafik-Cues und Pool-Bereiche setzen. Destination ist
   optional und bleibt zunächst leer. Die dort gespeicherten Netzwerkdaten
   ändern die MA-OSC-Konfiguration **nicht**.
5. `Plugin "QLab Control" "PLAN"` listet die vorgesehenen 24 Objekte:
   ein Layout, elf Macros und zwölf Appearances. Die Beispiele benötigen
   Layout 200, Macros 501–511 und Appearances 501–512.
6. `Plugin "QLab Control" "SELECT 101.2"` speichert die Auswahl ohne OSC.

Das geplante Layout verwendet drei Spalten in der spezifizierten Reihenfolge,
eine Statuszeile und unten SELECT CUE / SETUP. Es zeigt ausgewählten Cue,
letzten Song und zuletzt angeforderte Aktion getrennt. Es gibt keine
Online-Anzeige oder simulierten Fortschritt.

Spätere Show-Programmierung: `Plugin "QLab Control" "START 101.2"` in die
CMD-Spalte eines passenden Licht-Cues schreiben. Im aktuellen Build endet
dies absichtlich mit einer Meldung, ohne OSC zu senden. Gewöhnliche Licht-Cues
benötigen keinen Videobefehl. QLab muss Übergänge, Fades und das Stoppen alter
Gruppen selbst programmieren. NEXT ist manuelles GO am QLab-Playhead.

Setup-Werte liegen unter `QLC_V1_` in globalen Show-Variablen. Aktuell gibt
es eine Konfiguration pro Show; mehrere Installationen/Datenpools sind noch
nicht unterstützt. Schreibfehler können teilweise gespeicherte Werte hinterlassen;
das Konfigurationskennzeichen bleibt dann inaktiv. Setup erneut vollständig speichern.
Ein erneutes Setup setzt die vorhandene Cue-Auswahl nicht zurück.
