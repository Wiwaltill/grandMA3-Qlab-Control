-- Runtime adapter. Unverified writes/transmission deliberately fail closed.
local M={}
function M.new(core, api, guide)
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
    local function read(key) return api.GetVar(api.GlobalVars(),prefix..key) end
    local function write(key,value)
        assert(api.SetVar(api.GlobalVars(),prefix..key,value), 'Speichern fehlgeschlagen: '..key)
    end
    function self.load()
        local c={}
        for k in pairs(core.defaults) do c[k]=read(k) end
        return core.config(c)
    end
    function self.setup()
        local c=self.load()
        local inputs={}
        for _,field in ipairs(fields) do
            inputs[#inputs+1]={name=field[2],value=tostring(c[field[1]])}
        end
        local r=api.MessageBox({title='QLab Control — Einstellungen',
            message='QLab-Ziel und Port werden nur gespeichert. MA-OSC separat einrichten (OSC-Anleitung schließt diese Eingabe ohne Speichern). Die OSC-Ausgabe dieses Entwicklungsstands ist noch gesperrt.',
            commands={{value=1,name='Speichern'},{value=2,name='OSC-Anleitung'},{value=0,name='Abbrechen'}},inputs=inputs})
        if r and r.success and r.result==2 then return self.oscHelp() end
        if not r or not r.success or r.result~=1 then return end
        local valid=decode(r.inputs)
        -- Validation completes before the first write. Persistence is not transactional.
        write('configured',0)
        for k,v in pairs(valid) do write(k,v) end
        write('configured',1)
        return valid
    end
    function self.select()
        local r=api.MessageBox({title='Song-Cue auswählen',message='Cue-Nummer aus Ziffern eingeben. Dezimalstellen mit Punkt, z. B. 101.2.',
            commands={{value=1,name='Auswählen'},{value=0,name='Abbrechen'}},
            inputs={{name='Cue-Nummer',value=read('selected') or ''}}})
        if r and r.success and r.result==1 then write('selected',core.cue(r.inputs['Cue-Nummer'])) end
    end
    function self.plan()
        local p=core.plan(self.load())
        api.Printf('QLab Control: Installationsplan mit %d Objekten; keine Pool-Änderungen.',#p.objects)
        for _,o in ipairs(p.objects) do api.Printf('%s %d: %s',o.kind,o.id,o.label) end
        return p
    end
    function self.run(argument)
        local command=core.parse(argument or 'SETUP')
        if command.action=='OSCHELP' then return self.oscHelp() end
        if command.action=='SETUP' then return self.setup() end
        if command.action=='PLAN' then return self.plan() end
        if command.action=='SELECT' then
            if command.cue then write('selected',command.cue); return end
            return self.select()
        end
        if command.action=='INSTALL' or command.action=='UPDATE' or command.action=='UNINSTALL' then
            error('Pool-Installation noch gesperrt: Schema und Eigentumsprüfung auf 2.5.1.1 stehen aus. PLAN zeigt die vorgesehenen Objekte.')
        end
        assert(tonumber(read('configured'))==1,'Zuerst die Einstellungen mit SETUP speichern')
        local confirmed=false
        if command.action=='PANIC' or command.action=='NEXT' or command.action=='TEST' then
            local messages={PANIC='NOTSTOPP blendet ALLE Cues in allen auf diesem Port empfangenden Workspaces aus und stoppt sie. Erneutes Auslösen während der Blende stoppt sofort. Fortfahren?',
                NEXT='NÄCHSTER CUE löst GO an der QLab-Abspielposition aus. Die ausgewählte Cue-Nummer wird nicht hochgezählt. Fortfahren?',
                TEST='Dieser Test fordert den Start eines echten QLab-Cues an. Fortfahren?'}
            local r=api.MessageBox({title=({PANIC='NOTSTOPP',NEXT='NÄCHSTER CUE',TEST='OSC-Test'})[command.action],message=messages[command.action],
                commands={{value=1,name='Bestätigen'},{value=0,name='Abbrechen'}}})
            confirmed=r and r.success and r.result==1
            if not confirmed then return end
        end
        core.request(command,self.load(),{selected=read('selected'),song=read('song')},confirmed)
        error('OSC-Ausgabe gesperrt: SendOSC ohne Argumente muss auf 2.5.1.1 geprüft werden. Es wurde kein OSC gesendet.')
    end
    return self
end
return M
