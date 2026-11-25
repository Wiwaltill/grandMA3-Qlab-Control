# QLab Control installieren und testen

Version **0.2.0-beta.4**, Ziel grandMA3 **2.5.1.1** / QLab **5**.
Installer und Transport sind implementiert; Laufzeittests auf MA/QLab stehen aus.
Eine gesicherte Testshow verwenden. Während der Installation keine anderen
Nutzer die betroffenen Pool-Bereiche bearbeiten lassen.

## Import und Einstellungen

1. `QLab Control.xml` und `QLab Control.lua` liegen lokal gemeinsam in
   `~/MALightingTechnology/gma3_library/datapools/plugins/`.
   Alternativ das ZIP `QLab-Control-0.2.0-beta.4-import.zip` in den MA-Datenordner
   entpacken; es enthält die passende `gma3_library/datapools/plugins/`-Struktur.
2. Einen freien Plugin-Slot bearbeiten, **Import → lokales Laufwerk →
   QLab Control.xml** wählen. Einen bisherigen Teststand gezielt aktualisieren.
   Plugin antippen.
   Das XML enthält ab beta.2 den vollständigen Lua-Code. Die separate Lua-Datei
   bleibt zum Nachlesen enthalten, wird für diesen Import aber nicht benötigt.
   Beim Start muss `QLab Control 0.2.0-beta.4 gestartet` in der Command Line
   History erscheinen. Fehlt die Meldung, ist der neue Code noch nicht gestartet.
   Im Einstellungsfenster muss ebenfalls **0.2.0-beta.4** im Titel stehen.
   Dateien auf der Festplatte zu ersetzen aktualisiert einen bereits im Showfile
   gespeicherten Plugin-Code nicht automatisch: dafür das XML neu importieren.
3. QLab-Ziel, Port und MA-OSC-Zeilennummer eintragen. Ziel/Port sind Informationen;
   die MA-Route wird manuell nach der [OSC-Anleitung](OSC-ANLEITUNG-DE.md) eingerichtet.
4. Pool-Nummern festlegen. Standard: **Layout 200**, **Makros 501–511** und
   **Appearances 501–512**. Die Bereiche müssen frei sein oder nachgewiesen
   dieser Installation gehören.

## Automatisch installieren

**Layout installieren** übernimmt die Eingaben und erstellt 24 Pool-Objekte.
Es sendet kein OSC und führt kein Makro aus. Alternativ nach **Speichern**:

```text
Plugin "QLab Control" "INSTALL"
```

Im **Layout Viewer** das konfigurierte Layout wählen, **Zoom to Fit** ausführen
und den Setup-Modus ausschalten. Drei Spalten enthalten die Transportaktionen,
Pausengrafik, Schwarzbild und Notstopp; darunter Cue-Auswahl und Einstellungen.
Oben stehen Auswahl, letzter Song, letzte Anforderung und OSC-Ausgang.
Die Anzeige bestätigt keine Wiedergabe oder Verbindung.

`INSTALL` oder `UPDATE` aktualisiert die verwalteten Inhalte. Eigene Änderungen
an generierten Eigenschaften werden dabei überschrieben. Fremde/ersetzte
Objekte oder hinzugefügte Kindobjekte führen zum Abbruch vor der ersten Änderung.
Labels allein reichen nicht als Eigentumsnachweis.

Nach einem Fehler bleiben bereits erstellte Objekte mit einem Journal erhalten.
Fehler beheben und `INSTALL` erneut aufrufen oder `UNINSTALL` verwenden.
Nicht fremde Objekte in eine teilweise installierte Struktur einfügen.
Veränderte Identitäten werden nicht automatisch übernommen oder gelöscht.

## Einen echten OSC-Test ausführen

1. MA-OSC und QLab-Zugriff nach der Anleitung manuell einrichten.
2. In QLab einen ungefährlichen Test-Cue mit eigener Nummer vorbereiten.
3. Plugin → Einstellungen → **OSC-Test** wählen, Test-Cue eingeben und dann
   den Start ausdrücklich bestätigen. Der Test nutzt **gespeicherte** Werte;
   geänderte Einstellungen vorher speichern.
4. Alternativ `Plugin "QLab Control" "TEST 999"` aufrufen; `999` durch die eigene
   Test-Cue-Nummer ersetzen.
5. QLab beobachten. Der Test führt einen echten adressreinen SendOSC-Aufruf aus.
   Diese Form ohne Argumente muss auf 2.5.1.1 geprüft werden. Ein MA-`OK`
   bestätigt nur die Befehlsannahme, weder UDP-Empfang noch Wiedergabe.

Es gibt keine automatische Wiederholung. Bei Syntaxfehler oder fehlender
QLab-Reaktion Fehlermeldung und Paketmitschnitt prüfen. Installation und normales
Speichern lösen keinen Test aus.

## Show programmieren

```text
Plugin "QLab Control" "SELECT 101.2"
Plugin "QLab Control" "START 101.2"
Plugin "QLab Control" "PAUSE"
Plugin "QLab Control" "RESUME"
Plugin "QLab Control" "STOP"
```

Explizite START-Befehle in die CMD-Spalte der passenden Licht-Cues setzen.
Gewöhnliche Licht-Cues brauchen keinen Video-Befehl. IDLE und BLACKOUT starten
Grafik-Cues, ohne die Songreferenz zu verlieren. NEXT löst nach Bestätigung
QLab-GO an der aktuellen Abspielposition aus. PANIC betrifft alle auf dem Port
empfangenden Workspaces und verlangt Bestätigung. NEUSTART bleibt bis zur
Definition verlässlicher QLab-Gruppensemantik gesperrt. Übergänge, Fades und
Stopps vorheriger Gruppen werden in QLab programmiert.

## Entfernen und Pool-Nummern ändern

`Plugin "QLab Control" "UNINSTALL"` entfernt nach Bestätigung ausschließlich
nachgewiesene Objekte. Die MA-OSC-Konfiguration und gespeicherte Plugin-Werte
bleiben bestehen. Erst danach Pool-Nummern ändern und neu installieren.

Eine Konfiguration pro Show; Installer und installierter Transport sind an den
ursprünglichen Datenpool gebunden. Handle-Stabilität nach Show-Neuladen ist noch
zu prüfen. Bei abweichenden Identitäten bricht das Plugin sicher ab. Keine
Neuübernahme anhand ähnlich benannter Pool-Objekte erzwingen.
