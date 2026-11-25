# Kompatibilitätsprüfung — 2026-11-25

Ziel: grandMA3 **2.5.1.1**, QLab **5**. Die konkrete QLab-Unterversion ist
noch zu bestätigen. Keine Konsole, kein onPC und kein QLab wurden hier ausgeführt.
Die MA-Webhilfe ist nach 2.5, nicht nach Patch 2.5.1.1 versioniert;
einige Lua-Seiten zeigen trotz 2.5-Pfad den Stand 2.2 an.

| Bereich | Offizielle Grundlage | Ergebnis / offener Nachweis |
| --- | --- | --- |
| Plugin-Argument | [Plugin, MA 2.5](https://help2.malighting.com/grandMA3/2.5/HTML/keyword_plugin.html) | `return function(display_handle, argument)` und `Plugin 1 "START 101.2"` dokumentiert; Zielsystemtest offen |
| Grafisches Setup | [MessageBox](https://help2.malighting.com/grandMA3/2.5/HTML/lua_objectfree_messagebox.html) | `inputs`, `commands`, `success`, `result` dokumentiert; Darstellung auf Zielsystem offen |
| Show-Variablen | [GlobalVars](https://help.malighting.com/grandMA3/2.5/HTML/lua_objectfree_globalvars.html) | GlobalVars/GetVar/SetVar dokumentiert; Save/Reload und mehrere Datenpools offen |
| MA OSC | [SendOSC, MA 2.5](https://help.malighting.com/grandMA3/2.5/HTML/keyword_sendosc.html) | Typisierte Nachrichten dokumentiert; argumentfreie Nachricht nicht ausdrücklich belegt. Kein Ersatz mit erfundenem String-/Impulse-Argument |
| QLab Transport | [OSC Dictionary v5](https://qlab.app/docs/v5/scripting/osc-dictionary-v5/) | Semantische Nachrichten `/cue/{number}/start`, `/stop`, `/pause`, `/resume`, `/go`, `/panic`; keine Argumente für diese Aktionen |
| Netzwerk | [QLab OSC](https://qlab.app/docs/v5/networking/using-osc/) | Port und Rechte manuell konfigurieren; mehrere Workspaces am selben Port berücksichtigen |
| Restart | QLab OSC Dictionary v5 | Kein behauptetes atomisches Restart; Stop/Start über UDP garantiert weder Reihenfolge noch Abschluss. Bis Integrationstest gesperrt |
| XML / Pool-Adapter | [MA Plugins](https://help.malighting.com/grandMA3/2.5/HTML/plugins.html) | Export einer nativen 2.5.1.1-Referenz benötigt: Plugin mit LuaComponent, Layout mit Macro-Zuweisung, Appearance und Macro-Zeile. Schema/Properties und Import-Roundtrip noch offen |

Die reinen Lua-Tests beweisen Parser, Zustandsmodell, Plan und Adapter-Grenzen.
Sie beweisen keine MA-Lauffähigkeit und keine OSC-Zustellung. Das Build enthält einen XML-Einstieg mit externer LuaComponent entsprechend
der offiziellen Plugin-Dokumentation. Die Tags UserPlugin und ComponentLua sind
auch in lokal vorhandenen MA-Beispielen belegt; eine vorhandene Plugin-Datei trägt
DataVersion 2.5.1.1. Fremder Lua-Code wird nicht übernommen. Der Import-Roundtrip
auf 2.5.1.1 sowie Pool-/Netzwerkschreibzugriffe bleiben noch ungeprüft.

Numerische Cue-Strings einschließlich einer Dezimalstelle werden unterstützt;
alphanumerische QLab-Cue-Nummern sind in dieser ersten Implementierung bewusst
nicht freigegeben. Führende und nachgestellte Nullen bleiben erhalten.

Die nicht präfixierten OSC-Adressen betreffen alle offenen QLab-Workspaces,
die auf dem Zielport lauschen. Für V1 einen dedizierten Workspace-Port nutzen.
Panic blendet aus und stoppt; ein weiterer Panic während der Blende stoppt sofort.
