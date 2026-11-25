# Changelog

## 0.2.0-beta.7

- Enum-Eigenschaften werden bei abweichendem Rohwert zusätzlich mit der
  dokumentierten Enums.Roles.Edit-Rolle als Text gelesen und geprüft.
  Behebt „Action = Go+ (gelesen 3)“ und denselben Fehlerweg bei Textausrichtung.
- Keine fest verdrahtete Go+-Indexzuordnung. Falsche Texte oder nicht auflösbare
  Indizes führen weiterhin zum sicheren Abbruch.
- Mock simuliert Enum-Indizes; Fortsetzen der Teilinstallation und Ablehnung
  einer falschen Aktion sind durch Regressionstests abgedeckt.

## 0.2.0-beta.6

- Eigenschaftsprüfung akzeptiert native MA-Boolean-Werte für Yes/No, zusätzlich
  zu numerischen und textuellen Darstellungen. Behebt den fälschlichen Abbruch
  „Enabled = Yes (gelesen true)“ beim Erstellen der Makros.
- Falsche oder unbekannte Zustände werden weiterhin abgelehnt; kein pauschales
  Lua-Truthiness-Matching (0 und "false" sind in Lua wahrheitswertig).
- Mock verwendet standardmäßig native Boolean-Rückgaben; Wiederaufnahme einer
  Teilinstallation sowie wiederholte Installation damit geprüft.

## 0.2.0-beta.5

- SendOSC-Befehle behalten bei Nachrichten ohne Argumente beide Trennkommas:
  `/cue/999/start,,` statt `/cue/999/start`. Die bisherige Form wurde auf dem
  Nutzer-onPC mit „Illegal value“ abgelehnt.
- Sendefehler zeigen den vollständigen Befehl. Keine automatischen
  Wiederholungen und keine Dummy-Argumente.
- Mock bildet die beobachtete Ablehnung ab; Formatprüfung für alle Transportaktionen.
  Erfolg der korrigierten Form auf MA/QLab ist noch zu bestätigen.

## 0.2.0-beta.4

- Einheitliche Importdatei `QLab Control.xml`; die zusätzliche versionierte
  Beta-XML wurde auf Wunsch entfernt.
- Einstellungs- und Fehlerfenster zeigen die Build-Version, damit ein weiterhin
  im Showfile gespeicherter Altstand sofort erkennbar ist.
- Erneuter Screenshot mit tonumber an Zeile 297 entspricht dem alten
  beta.1/beta.2-Code; der beta.3-Fix bleibt unverändert enthalten.

## 0.2.0-beta.3

- GetVar-Adapter liefern ausdrücklich genau einen Wert. Zusätzliche
  MA-Rückgabewerte können dadurch nicht mehr als zweites Argument (Zahlenbasis)
  an tonumber gelangen. Behebt den reproduzierten Fehler „string expected,
  got number“ bei der Prüfung des Konfigurationskennzeichens.
- Derselbe Fehlerweg im Eigentums-/Statusadapter korrigiert.
- Regressionstest mit zusätzlichen numerischen, booleschen und Textwerten
  für Installation, Auswahl, OSC-Test, Status und Cleanup.

## 0.2.0-beta.2

- Plugin-Handle wird erst bei der Installation im geschützten Aufruf aufgelöst.
  Kein Zugriff auf MA-Handles mehr beim Laden der LuaComponent.
- XML enthält den vollständigen Lua-Code im nativen FileContent-/Base64-Format;
  der Start hängt nicht mehr von einer externen Lua-Datei ab.
- Start schreibt die Build-Version in die Command Line History. Regressionstest
  für Setup-Start mit nicht verfügbarem Parent-Handle; XML-Inhalt wird bytegenau
  mit dem Lua-Build verglichen und unter Lua 5.4 geladen.
- Der auf dem Nutzer-onPC beobachtete stille Startfehler ist damit abgesichert;
  dessen genaue Ursache und die Behebung auf dem Zielsystem sind noch zu bestätigen.

## 0.2.0-beta.1

- Automatische Installation von Layout, elf Makros und zwölf Appearances.
- Vollständiger Konflikt-Preflight, datenpoolgebundenes Eigentumsjournal mit
  Kindobjekt-Identitäten, Wiederinstallation/Update und bestätigtes Cleanup.
- Eigener bestätigter OSC-Test über Setup oder TEST mit Cue-Nummer;
  echte SendOSC-Aufrufe und Last-Requested-Status nach MA-Befehlsannahme.
- Mock-Tests für Kollisionen, ersetzte Objekte, Teilfehler, Datenpoolwechsel,
  Testabbruch, Sendefehler und Transportzustände.
- MA-/QLab-Tests, Paketformatprüfung und Save/Reload offen; Restart gesperrt.

## 0.1.0-dev.4

- OSC-Anleitung als fünfseitiger nativer Assistent mit Fortschrittsanzeige,
  Plugin-Fensterrahmen, Symbol und Zurück-/Weiter-Navigation gestaltet.
- Kurze Abschnitte für QLab, MA und Plugin; Abschlussübersicht zeigt die
  gespeicherten Verbindungswerte ohne Verbindungsbestätigung.
- Navigation, Abbruch und unveränderte Einstellungen mit Mocks geprüft.
  Visuelle Prüfung auf MA-Displays steht aus.

## 0.1.0-dev.3

- Deutsche Setup-Felder, Dialoge, Bestätigungen, Fehlermeldungen und Layout-Texte.
  Technische Befehle und vorhandene Show-Variablen bleiben kompatibel.
- OSC-Kurzhilfe im Setup und über OSCHELP; ausführliche deutsche Netzwerkanleitung.
- Keine automatische Änderung der MA-OSC-Konfiguration: sichere Schreibzugriffe
  und Konfliktbehandlung auf 2.5.1.1 sind weiterhin nicht verifiziert.

## 0.1.0-dev.2

- MA-XML-Einstieg mit externer LuaComponent ergänzt; ZIP verwendet die native
  Ordnerstruktur `gma3_library/datapools/plugins/`.
- XML-/Lua-Referenz, ZIP-Inhalt und LICENSE werden automatisch geprüft.
- Importanleitung ersetzt manuelles Einfügen von Lua-Code. Import auf onPC,
  Pool-Installer und OSC-Ausgabe bleiben offen.

## 0.1.0-dev.1

- Erster reiner Lua-Kern: Whitelist-Parser, Konfiguration, Cue-Strings,
  Transportabsichten und getrennte Song-/Auswahl-/Anforderungszustände.
- Native MessageBox für Setup und Cue-Auswahl; persistente Show-Variablen.
- Vollständiger Layout-/Pool-Datenplan und identitätsbasierter Konflikt-Preflight.
- Mock-Tests und reproduzierbarer Build einer einzelnen LuaComponent.
- Pool-Schreiben, OSC-Encoding, Restart und Import-XML bleiben bis zur
  Verifikation auf grandMA3 2.5.1.1 gesperrt. Kein fertiges V1-Release.
