# Test- und Release-Gates

Automatisch lokal:

```sh
python3 -m pip install lupa
python3 tools/build.py
python3 tools/test.py
```

Die Tests führen den tatsächlichen Lua-Code unter Lua 5.4 aus. MA-APIs werden
gemockt. Netzwerk und Pool-Mutationen sind in diesem Meilenstein gesperrt.

Vor dem nächsten Meilenstein auf 2.5.1.1:

- Plugin-Aufruf über Nummer und Name, Kommandozeile und Sequence-CMD testen.
- Native Export-Fixtures für LuaComponent, Macro-Zeile, Appearance und Layout
  erzeugen; Properties und Dateistruktur protokollieren; Import/Export-Roundtrip.
- Argumentfreies SendOSC isoliert per Paketmitschnitt prüfen: OSC-Adresse,
  leere Typenliste, keine zusätzlichen Argumente. Anschließend dedizierten
  QLab-Testcue starten. Kein Test beim Setup oder bei der Installation.
- MessageBox: Speichern, Abbrechen, ungültige Werte, Tastatur und Displays.
- Show speichern/neu laden; User- und Datenpoolwechsel; Variablenpersistenz.

Vor einer vollständigen V1-Freigabe:

- Installer prüft ALLE Slots vor Schreibzugriff; Eigentumsmanifest mit stabiler
  Objektidentität und Datenpoolbindung; fremde und nachträglich ersetzte Objekte
  niemals verändern. Label allein genügt nicht.
- Installieren, erneut installieren, Update, partielle Fehler und Cleanup mit
  leeren/belegten Pools und geänderten Objekten testen. Keine OSC-Ausgabe dabei.
- Layout-Farben, Positionen, Status, Macro-Argumente und Lesbarkeit visuell prüfen.
- START/STOP/PAUSE/RESUME, Dezimal-Cues, Gruppenmodi, mehrere Videoausgänge,
  Songwechsel außerhalb der Reihenfolge und intra-song Trigger testen.
- Restart erst nach definierter und getesteter Cue-/Gruppensemantik freigeben.
- Idle/Blackout erhalten Songreferenz; NEXT-Warnung und Panic-Abbruch prüfen;
  getrennte Workspaces und getrennte Ports testen.
- Mac getrennt: weiterhin nur „last requested“, niemals bestätigte Wiedergabe.
- LICENSE unverändert beilegen; Version/Changelog aktualisieren; Import-ZIP
  in frischer Testshow prüfen; SHA-256 und Testprotokoll dem Release beilegen.

Noch kein GitHub Release veröffentlichen: alle Integrationstests sind offen.
