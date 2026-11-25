# Kompatibilitätsprüfung — 2026-11-26

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
| XML / Pool-Adapter | [MA Plugins](https://help.malighting.com/grandMA3/2.5/HTML/plugins.html) | Export einer nativen 2.5.1.1-Referenz benötigt: Plugin mit LuaComponent, Layout mit Macro-Zuweisung, Appearance und Macro-Zeile. Pool-Adapter implementiert; interne Eigenschaften werden vor jedem Schreiben über PropertyCount/PropertyName geprüft und danach gelesen. Import-Roundtrip und Zielsystemtest offen |

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

## 0.2.0-beta.1: Installer und echte Testanforderung

Die [MA-Store-Syntax](https://help.malighting.com/grandMA3/2.5/HTML/keyword_store.html),
[Layout-Zuweisung](https://help.malighting.com/grandMA3/2.5/HTML/layout_edit_view.html),
[Layout-Anordnung](https://help.malighting.com/grandMA3/2.5/HTML/layout_elements_edit.html),
[Get](https://help.malighting.com/grandMA3/2.5/HTML/lua_object_get.html),
[Set](https://help.malighting.com/grandMA3/2.5/HTML/lua_object_set.html) und
[Cmd-Rückgabe](https://help2.malighting.com/grandMA3/2.5/HTML/lua_objectfree_cmd.html)
sind dokumentiert. Ergänzend wurden die mit der lokalen MA-2.5.1-Installation
mitgelieferten API-Metadaten und Systemtests geprüft: Store an Pool-Adressen
verwendet ein Leerzeichen vor der Objekt-ID; Macro-/Layout-Kinder einen Punkt.
Die lokalen Beispiele belegen BackR/G/B/Alpha, PosX/Y, Width/Height,
CustomTextText/Color und GetAssignedObj. Fremder Plugin-Code wird nicht gebündelt.

Der echte Test führt beispielsweise `SendOSC 1 "/cue/999/start"` aus.
Diese adressreine Form für null Argumente ist in der offiziellen SendOSC-Seite
nicht ausdrücklich beschrieben. Sie ist deshalb **ein auszuführender
Integrationstest**, kein bereits validierter Wire-Encoder. Ein MA-Syntaxfehler
wird angezeigt; es gibt keine automatische Wiederholung oder Ersatznachricht.
Bei `OK` wird nur die letzte Anforderung gespeichert. QLab-Empfang muss beobachtet
und für die Freigabe das Paketformat geprüft werden.

Eigentumsnachweise verwenden HandleToStr plus die Identitäten sämtlicher
Kindobjekte. Wiederinstallieren oder Löschen mit fehlendem/abweichendem Nachweis
wird verweigert. Die Stabilität dieser Handles nach Save/Reload, PSR und
Showmigration muss auf MA geprüft werden. Falls sie sich ändern: keine
automatische Neuübernahme anhand von Labels. Eine Konfiguration pro Show;
Installationsumfang an den ursprünglichen Datenpool gebunden.
