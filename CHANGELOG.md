# Changelog

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
