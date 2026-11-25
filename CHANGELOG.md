# Changelog

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
