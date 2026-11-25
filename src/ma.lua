-- Runtime adapter. No network transmission during setup or installation.
local M={}
function M.new(core, api, guide, poolModule, plugin)
    local self={}
    local prefix='QLC_V1_'
    -- Stable storage keys and command tokens remain language-independent.
    local fields={
        {'destination','01 QLab-Ziel (IP, optional)'}, {'port','02 QLab-OSC-Port'},
        {'output','03 MA-OSC-Zeilennummer'}, {'idle','04 Pausengrafik-Cue'},
        {'blackout','05 Schwarzbild-Cue'}, {'layout','06 Layout-Nummer'},
        {'macro','07 Erste Makro-Nummer'}, {'appearance','08 Erste Appearance-Nummer'}
    }
    local function decode(inputs)
        assert(type(inputs)=='table','Keine Eingaben vom Einstellungsfenster erhalten')
        local values={}
        for _,field in ipairs(fields) do
            assert(type(inputs[field[2]])=='string','Eingabefeld fehlt: '..field[2])
            values[field[1]]=inputs[field[2]]
        end
        return core.config(values)
    end
    function self.oscHelp()
        local pages=guide.pages(self.load())
        local index=1
        while true do
            local commands={{value=0,name='Schließen'}}
            if index>1 then commands[#commands+1]={value=1,name='Zurück'} end
            if index<#pages then commands[#commands+1]={value=2,name='Weiter'} end
            local progress={}
            for i=1,#pages do progress[i]=i==index and '[ '..i..' ]' or tostring(i) end
            local r=api.MessageBox({
                title='OSC-Anleitung  |  '..index..' / '..#pages..'  —  '..pages[index].title,
                icon='object_smart',backColor='Window.Plugins',
                titleTextColor='Global.Text',messageTextColor='Global.Text',
                message=table.concat(progress,'    ')..'\n\n'..pages[index].message,
                commands=commands})
            if not r or not r.success or r.result==0 then return end
            if r.result==1 and index>1 then index=index-1
            elseif r.result==2 and index<#pages then index=index+1
            else return end
        end
    end
    local function read(key)
        -- A tail return forwards every MA return value. In tonumber(read(...)),
        -- an auxiliary value would become the numeric-base argument.
        local value=api.GetVar(api.GlobalVars(),prefix..key)
        return value
    end
    local function write(key,value)
        assert(api.SetVar(api.GlobalVars(),prefix..key,value), 'Speichern fehlgeschlagen: '..key)
    end
    function self.load()
        local c={}
        for k in pairs(core.defaults) do c[k]=read(k) end
        return core.config(c)
    end
    local function poolAdapter()
        return assert(poolModule,'Pool-Modul fehlt').new(core,api,self.load(),plugin)
    end
    local function state()
        local s={}
        for _,k in ipairs({'selected','song','lastAction','lastCue'}) do
            local v=read(k); if v and v~='' then s[k]=v end
        end
        return s
    end
    local function refresh()
        -- Status failure after a successful send must never trigger a resend.
        if not poolModule then return end
        local ok,err=pcall(function() poolAdapter().status(state()) end)
        if not ok then api.Printf('QLab Control: %s',tostring(err)) end
    end
    function self.lifecycle(action)
        assert(tonumber(read('configured'))==1,'Zuerst Einstellungen speichern')
        local adapter=poolAdapter()
        adapter.preflight()
        if action=='UNINSTALL' then
            local r=api.MessageBox({title='QLab Control entfernen',
                message='Nur die nachgewiesenen Plugin-Objekte entfernen? Die OSC-Konfiguration bleibt bestehen.',
                commands={{value=1,name='Entfernen'},{value=0,name='Abbrechen'}}})
            if not r or not r.success or r.result~=1 then return end
            adapter.uninstall()
        else
            adapter.install(); refresh()
        end
        api.MessageBox({title='QLab Control',message=action=='UNINSTALL' and 'Plugin-Pool-Objekte entfernt.' or
            'Layout, Makros und Appearances angelegt/aktualisiert. Im Layout Viewer das konfigurierte Layout wählen und Zoom to Fit ausführen. Es wurde kein OSC gesendet.',
            commands={{value=0,name='Schließen'}}})
    end
    function self.setup()
        local c=self.load()
        local inputs={}
        for _,field in ipairs(fields) do
            inputs[#inputs+1]={name=field[2],value=tostring(c[field[1]])}
        end
        local r=api.MessageBox({title='QLab Control '..core.version..' — Einstellungen',
            message='Speichern / Installieren übernimmt die Eingaben. Netzwerkdaten ändern keine MA-OSC-Route. Anleitung und OSC-Test verwenden die bereits gespeicherten Werte.',
            commands={{value=1,name='Speichern'},{value=2,name='OSC-Anleitung'},
                {value=3,name='Layout installieren'},{value=4,name='OSC-Test'},{value=0,name='Abbrechen'}},inputs=inputs,
            autoCloseOnInput=false})
        if r and r.success and r.result==2 then return self.oscHelp() end
        if r and r.success and r.result==4 then return self.run('TEST') end
        if not r or not r.success or (r.result~=1 and r.result~=3) then return end
        local valid=decode(r.inputs)
        local installed=api.GetVar(api.GlobalVars(),'QLC_V1_owned_scope')
        if installed and installed~='' then
            poolAdapter().preflight()
            assert(valid.layout==c.layout and valid.macro==c.macro and valid.appearance==c.appearance,
                'Pool-Nummern erst nach UNINSTALL ändern')
        end
        -- Validation completes before the first write. Persistence is not transactional.
        write('configured',0)
        for k,v in pairs(valid) do write(k,v) end
        write('configured',1)
        if r.result==3 then return self.lifecycle('INSTALL') end
        refresh()
        return valid
    end
    function self.select()
        local r=api.MessageBox({title='Song-Cue auswählen',message='Cue-Nummer aus Ziffern eingeben. Dezimalstellen mit Punkt, z. B. 101.2.',
            commands={{value=1,name='Auswählen'},{value=0,name='Abbrechen'}},
            inputs={{name='Cue-Nummer',value=read('selected') or ''}}})
        if r and r.success and r.result==1 then write('selected',core.cue(r.inputs['Cue-Nummer'])); refresh() end
    end
    function self.plan()
        local p=core.plan(self.load())
        api.Printf('QLab Control: Installationsplan mit %d Objekten; keine Pool-Änderungen.',#p.objects)
        for _,o in ipairs(p.objects) do api.Printf('%s %d: %s',o.kind,o.id,o.label) end
        return p
    end
    function self.run(argument)
        local command=core.parse((not argument or argument:match('^%s*$')) and 'SETUP' or argument)
        if command.action=='OSCHELP' then return self.oscHelp() end
        if command.action=='SETUP' then return self.setup() end
        if command.action=='PLAN' then return self.plan() end
        if command.action=='SELECT' then
            if command.cue then write('selected',command.cue); refresh(); return end
            return self.select()
        end
        if command.action=='INSTALL' or command.action=='UPDATE' or command.action=='UNINSTALL' then
            return self.lifecycle(command.action)
        end
        assert(tonumber(read('configured'))==1,'Zuerst die Einstellungen mit SETUP speichern')
        local installed=api.GetVar(api.GlobalVars(),'QLC_V1_owned_scope')
        if installed and installed~='' then poolAdapter().preflight() end
        if command.action=='TEST' and not command.cue then
            local r=api.MessageBox({title='Echter QLab-OSC-Test',
                message='Eigene ungefährliche Test-Cue-Nummer eingeben. Kein Test beim Installieren oder Speichern.',
                inputs={{name='Test-Cue',value=''}},
                commands={{value=1,name='Weiter'},{value=0,name='Abbrechen'}}})
            if not r or not r.success or r.result~=1 then return end
            command.cue=core.cue(r.inputs['Test-Cue'])
        end
        -- Validate before displaying a destructive-action confirmation.
        local messages,nextState=core.request(command,self.load(),state(),true)
        local confirmed=false
        if command.action=='PANIC' or command.action=='NEXT' or command.action=='TEST' then
            local messages={PANIC='NOTSTOPP blendet ALLE Cues in allen auf diesem Port empfangenden Workspaces aus und stoppt sie. Erneutes Auslösen während der Blende stoppt sofort. Fortfahren?',
                NEXT='NÄCHSTER CUE löst GO an der QLab-Abspielposition aus. Die ausgewählte Cue-Nummer wird nicht hochgezählt. Fortfahren?',
                TEST='Cue '..(command.cue or '')..' über MA-OSC-Zeile '..self.load().output..
                    ' starten? Der SendOSC-Aufruf ohne Argumente wird hier erstmals auf deinem System geprüft. QLab selbst beobachten; dies ist keine Empfangsbestätigung.'}
            local r=api.MessageBox({title=({PANIC='NOTSTOPP',NEXT='NÄCHSTER CUE',TEST='OSC-Test'})[command.action],message=messages[command.action],
                commands={{value=1,name='Bestätigen'},{value=0,name='Abbrechen'}}})
            confirmed=r and r.success and r.result==1
            if not confirmed then return end
        end
        for _,message in ipairs(messages) do
            local osc=core.oscCommand(self.load().output,message)
            local result=api.Cmd(osc)
            assert(result=='OK','SendOSC nicht ausgeführt: '..tostring(result)..'\nBefehl: '..osc..
                '\nBei erneutem Fehler MA-OSC-Zeilennummer und Send Command prüfen. Keine automatische Wiederholung.')
        end
        for _,k in ipairs({'selected','song','lastAction','lastCue'}) do write(k,nextState[k] or '') end
        refresh()
        api.Printf('QLab Control: zuletzt angefordert %s %s; keine Wiedergabebestätigung.',
            nextState.lastAction or '',nextState.lastCue or '')
        if command.action=='TEST' then
            api.MessageBox({title='OSC-Test angefordert',
                message='MA hat den SendOSC-Befehl angenommen. Jetzt Cue '..command.cue..
                    ' in QLab prüfen. UDP-Empfang und Wiedergabe sind damit nicht bestätigt.',
                commands={{value=0,name='Schließen'}}})
        end
    end
    return self
end
return M
