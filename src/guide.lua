-- Presentation model only. No API calls, network access or configuration writes.
local M={}
function M.pages(c)
    local destination=c.destination~='' and c.destination or '(IP des QLab-Macs eintragen)'
    return {
        {title='Überblick',message=table.concat({
            'QLab Control  /  VERBINDUNG EINRICHTEN',
            '',
            'grandMA3   →   OSC / UDP   →   QLab',
            '',
            '01  QLab vorbereiten',
            '02  MA-Ausgang einrichten',
            '03  Werte im Plugin zuordnen',
            '',
            'Diese Anleitung ändert keine Einstellungen.',
            'Entwicklungsstand: Plugin-OSC-Ausgabe noch gesperrt.'},'\n')},
        {title='QLab vorbereiten',message=table.concat({
            'IN QLAB ÖFFNEN',
            'Workspace Settings → Network → OSC Access',
            '',
            'Allow OSC connections     einschalten',
            'No Passcode → Control     erlauben',
            'OSC listening port              '..c.port,
            '',
            'Mac und MA: gleiches erreichbares Show-Netz.',
            'Nur im isolierten Netz; keine Passcode-Anmeldung im Plugin.',
            'Mehrere Workspaces: je einen eigenen OSC-Port verwenden.'},'\n')},
        {title='MA-Ausgang einrichten',message=table.concat({
            'IN GRANDMA3 ÖFFNEN',
            'Menü → In & Out → OSC  /  eigene freie Zeile',
            '',
            'Destination IP     '..destination,
            'Mode                     UDP',
            'Port                       '..c.port,
            'Prefix                    leer lassen',
            'Send Command     Yes',
            '',
            'Show-Netzwerkschnittstelle unter Interface wählen.',
            'Vor Enable Output alle bestehenden OSC-Zeilen prüfen.'},'\n')},
        {title='Plugin-Werte zuordnen',message=table.concat({
            'IM PLUGIN SPEICHERN',
            'QLab Control → Einstellungen',
            '',
            'QLab-Ziel                     '..destination,
            'QLab-OSC-Port            '..c.port,
            'MA-OSC-Zeilennummer   '..c.output,
            '',
            'Ziel und Port sind nur gespeicherte Informationen.',
            'Die Zeilennummer muss zu deinem MA-Ausgang passen.',
            'Speichern legt keine OSC-Zeile an und sendet nichts.'},'\n')},
        {title='Prüfen & abschließen',message=table.concat({
            'DEINE VERBINDUNGSWERTE',
            'MA-Zeile '..c.output..'   →   '..destination..'   /   UDP '..c.port,
            '',
            'PRÜFEN',
            'Mac-IP • gemeinsamer Port • UDP • leeres Prefix',
            'MA-Interface • Enable Output • QLab-Control-Recht',
            '',
            'AKTUELL TESTBAR',
            'Import, Einstellungen, Cue-Auswahl und Installationsplan.',
            'QLab-Starttests sind in diesem Entwicklungsstand gesperrt.',
            'Diese Übersicht bestätigt keine Verbindung oder Wiedergabe.'},'\n')}
    }
end
return M
