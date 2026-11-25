# OSC zwischen grandMA3 und QLab einrichten

Stand: 0.1.0-dev.3, Ziel grandMA3 2.5.1.1 / QLab 5.
**Die Verbindung wird manuell eingerichtet. Die OSC-Ausgabe des Plugins bleibt
in diesem Entwicklungsstand gesperrt.** Auch eine korrekt eingerichtete Verbindung
führt daher derzeit noch keinen Plugin-Transportbefehl aus.

Im Plugin öffnet **OSC-Anleitung** die Kurzhilfe. Dieser Knopf schließt die
Eingabe ohne Speichern. Vorher geänderte Werte zuerst mit **Speichern** übernehmen.
Die Hilfe lässt sich auch mit `Plugin "QLab Control" "OSCHELP"` öffnen.

## 1. QLab vorbereiten

1. QLab-Mac und MA mit demselben Show-Netz verbinden; passende IP-Adressen
   und Netzmasken verwenden. In QLab **Workspace Settings → Network → OSC Access**
   öffnen. Dort wird auch die IP-Adresse des Macs angezeigt.
2. **Allow OSC connections** aktivieren. Für diesen Plugin-Entwurf unter
   **No Passcode** das Recht **Control** erlauben. Das Plugin implementiert
   keine Passcode-Anmeldung. Nur im vertrauenswürdigen, isolierten Show-Netz
   verwenden; Edit-Zugriff ist für Transportbefehle nicht nötig.
3. Den **OSC listening port** notieren, standardmäßig `53000`.
   Gemeint ist OSC, nicht der separate Plain-Text-Port `53535`.
   Bei mehreren Workspaces einen eigenen Port je Workspace verwenden:
   unpräfixierte Befehle erreichen alle Workspaces, die am Zielport lauschen.

Grundlage: [QLab Workspace Settings](https://reference.qlab.app/docs/v5/fundamentals/workspace-settings/)
und [QLab OSC Dictionary](https://qlab.app/docs/v5/scripting/osc-dictionary-v5/).

## 2. grandMA3 einstellen

**Menü → In & Out → OSC** öffnen. Eine eigene freie Zeile anlegen;
bestehende Routen nicht überschreiben. Folgende Werte setzen:

| MA-Feld | Wert |
| --- | --- |
| Name | QLab Control |
| Destination IP | IP-Adresse des QLab-Macs |
| Mode | UDP |
| Port | QLab-OSC-Port, normalerweise 53000 |
| Prefix | leer |
| Send Command | Yes |

**Interface** auf die Show-Netzwerkschnittstelle stellen. Die Nummer der Zeile
notieren. Bestehende OSC-Zeilen prüfen, bevor **Enable Output** aktiviert wird:
Dieser Schalter gilt auch für andere Ausgänge. **Send** betrifft automatisches
MA-Playback-Feedback und ist dafür nicht nötig. **Enable Input**, **Receive** und
**Receive Command** werden für die einseitige Plugin-Steuerung nicht benötigt.
Bestehende Einstellungen anderer Anwendungen unverändert lassen.

Grundlage: [MA OSC, Version 2.5](https://help.malighting.com/grandMA3/2.5/HTML/remote_inputs_osc.html).

## 3. Werte im Plugin zuordnen

| Deutsches Setup-Feld | Bedeutung |
| --- | --- |
| 01 QLab-Ziel (IP, optional) | IP-Adresse des Macs, nur gespeicherte Information |
| 02 QLab-OSC-Port | Derselbe Port wie in QLab und MA, nur gespeicherte Information |
| 03 MA-OSC-Zeilennummer | Nummer der zuvor angelegten MA-OSC-Zeile |
| 04 Pausengrafik-Cue | Cue-Nummer der gewünschten QLab-Grafik |
| 05 Schwarzbild-Cue | Cue-Nummer des gewünschten QLab-Schwarzbilds |
| 06–08 Pool-Nummern | Geplante Bereiche für Layout, Makros und Appearances |

**Speichern** übernimmt die Werte in die Show-Variablen. Es erstellt keine
MA-OSC-Zeile, aktiviert keinen Ausgang und sendet keine Testnachricht.
Gespeicherte Einstellungen früherer englischer Builds bleiben lesbar.

## 4. Was lässt sich jetzt prüfen?

- XML importieren und Plugin aufrufen: Die Eingabe erscheint deutsch.
- Werte speichern und Setup erneut öffnen: dieselben Werte müssen erscheinen.
- OSC-Anleitung öffnen: Es darf keine Ausgabe und keine Konfigurationsänderung erfolgen.
- `SELECT 101.2` speichert eine Cue-Auswahl; `PLAN` listet geplante Pool-Objekte.

Ein tatsächlicher QLab-Starttest folgt erst nach Verifikation des argumentfreien
SendOSC-Formats. Die gesperrte Ausgabe ist kein Hinweis auf eine falsche IP.
Auch eine gelbe MA-Sendeanzeige wäre allein kein Beleg für QLab-Wiedergabe.

Bei späteren Verbindungstests prüfen: MA-Zeilennummer, Mac-IP, OSC-Port,
UDP, leeres Prefix, Schnittstelle, Firewall und QLab-Control-Recht. Keine
workspaceweiten Stopps als gewöhnlichen Songwechsel verwenden.

## Warum noch keine automatische Konfiguration?

Der [MA-OSC-Befehl](https://help.malighting.com/grandMA3/2.5/HTML/keyword_osc.html)
unterstützt Listen und Import/Export. Der vollständige Schreibzugriff mit
Konfliktprüfung, sicherem Update und Rücknahme ist für dieses Plugin auf
2.5.1.1 noch nicht verifiziert. Deshalb wird hier die manuelle Anleitung
verwendet; eine grundsätzlich unmögliche Automatisierung wird nicht behauptet.
