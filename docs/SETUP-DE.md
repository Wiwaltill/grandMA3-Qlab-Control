# Entwicklungsstand installieren und prüfen

Die Oberfläche ist deutsch. Die Schritt-für-Schritt-Anleitung für Netzwerk,
QLab-Rechte und MA-OSC steht in [OSC-ANLEITUNG-DE.md](OSC-ANLEITUNG-DE.md).
Im Setup öffnet **OSC-Anleitung** die Kurzhilfe ohne Speichern. Die technischen
Befehle (`SETUP`, `START`, `SELECT` usw.) bleiben unverändert.

Dies ist **0.1.0-dev.3**, eine importierbare Entwicklungsvorschau, kein fertiges
V1-Release. OSC, automatische Pool-Installation, Update und Cleanup sind noch
gesperrt. Testbar sind Import, Plugin-Aufruf, grafisches Setup, Cue-Auswahl
und die Ausgabe des Installationsplans.

1. Show sichern; eine Testshow in grandMA3 2.5.1.1 verwenden.
2. Die lokal bereitgestellten Dateien `QLab Control.xml` und `QLab Control.lua`
   liegen zusammen in `~/MALightingTechnology/gma3_library/datapools/plugins/`.
   Alternativ `python3 tools/build.py` ausführen und den Inhalt von
   `dist/QLab-Control-0.1.0-dev.3-import.zip` in den MA-Datenordner entpacken.
   Das ZIP enthält bereits `gma3_library/datapools/plugins/`.
3. Einen **freien** Plugin-Pool-Slot bearbeiten, **Import** wählen, das lokale
   Laufwerk und **QLab Control.xml** auswählen und importieren. Editor schließen
   und das Plugin antippen. Das Setup sollte erscheinen; kein Code-Einfügen nötig.
   Der tatsächliche Import auf onPC ist noch nicht von uns ausgeführt worden.
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
