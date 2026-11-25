-- MA pool adapter. All mutations are synchronous; never executes transport.
local M={}
function M.new(core,api,config,plugin)
    local self={}
    local vars=api.GlobalVars()
    local dp=assert(api.DataPool(),'Kein Datenpool')
    local pools={Layout=dp.Layouts,Macro=dp.Macros,Appearance=api.ShowData().Appearances}
    local plan=core.plan(config)
    local prefix='QLC_V1_owned_'
    local function read(k)
        local value=api.GetVar(vars,prefix..k)
        return value
    end
    local function save(k,v) assert(api.SetVar(vars,prefix..k,v),'Eigentumsnachweis nicht gespeichert: '..k) end
    local function key(o) return o.kind..'_'..o.id end
    local function object(o) return assert(pools[o.kind],'Pool fehlt: '..o.kind)[o.id] end
    local function identity(h)
        local id=api.HandleToStr(h)
        assert(type(id)=='string' and id~='','Objektidentität fehlt')
        return id
    end
    -- Includes descendants: an added/replaced macro line or layout element
    -- prevents update/cleanup. Names alone never establish ownership.
    local function tree(h)
        local ids={identity(h)}
        for _,child in ipairs(h:Children()) do ids[#ids+1]=tree(child) end
        return table.concat(ids,'|')
    end
    local scope=identity(dp)..'/'..config.layout..'/'..config.macro..'/'..config.appearance
    local function checkScope()
        assert(not read('scope') or read('scope')=='' or read('scope')==scope,
            'Installation gehört zu einem anderen Datenpool oder anderen Pool-Nummern. Dort zuerst UNINSTALL ausführen.')
    end
    local function owned(o,h)
        return read(key(o))==tree(h)
    end
    local function command(s)
        local result=api.Cmd(s)
        assert(result=='OK','MA-Befehl fehlgeschlagen: '..s..' ('..tostring(result)..')')
    end
    local function address(h)
        local a=h:ToAddr(false)
        assert(type(a)=='string' and a~='' and not a:find('[%c;]'),'Ungültige MA-Objektadresse')
        return a
    end
    -- Inspect properties before writing. Unsupported schema fails visibly.
    local function findProperty(h,wanted)
        for i=0,h:PropertyCount()-1 do
            local name=h:PropertyName(i)
            if name:lower()==wanted:lower() then return name end
        end
    end
    local function property(h,wanted)
        return assert(findProperty(h,wanted),'MA-Eigenschaft fehlt: '..wanted..' an '..address(h))
    end
    local function set(h,k,v)
        local p=property(h,k)
        h:Set(p,tostring(v))
        local actual=h:Get(p)
        local matches=core.propertyMatches(v,actual)
        assert(matches,'MA-Eigenschaft nicht übernommen: '..k..' = '..tostring(v)..' (gelesen '..tostring(actual)..')')
    end
    function self.preflight()
        checkScope()
        for _,o in ipairs(plan.objects) do
            local h=object(o)
            assert(not h or owned(o,h),'Fremdes oder verändertes Objekt: '..o.kind..' '..o.id)
        end
        return plan
    end
    local function remember(o) save(key(o),tree(assert(object(o)))) end
    local function create(o)
        local existing=object(o)
        if existing then
            assert(owned(o,existing),'Objekt inzwischen ersetzt: '..o.kind..' '..o.id)
            return existing
        end
        -- Recheck immediately before Store. Never merge into an occupied slot.
        assert(not object(o),'Pool-Slot inzwischen belegt')
        command('Store '..address(pools[o.kind])..' '..o.id..' /NoConfirmation')
        local h=assert(object(o),'Objekt wurde nicht angelegt: '..o.kind..' '..o.id)
        remember(o) -- Journal before decoration; partial installs remain removable.
        return h
    end
    local function decorate(o,fn)
        assert(object(o) and owned(o,object(o)),'Objekt vor Bearbeitung verändert')
        local ok,err=pcall(fn)
        -- Capture children created by our synchronous commands even on failure.
        -- No automatic rollback of existing objects or foreign slots.
        if object(o) then remember(o) end
        if not ok then error(err) end
    end
    local function element(h,index)
        if not h[index] then command('Store '..address(h)..'.'..index..' /NoConfirmation') end
        return assert(h[index],'Layout-Element fehlt')
    end
    local function arrange(e,x,y,w,h,text)
        set(e,'PosX',x); set(e,'PosY',y); set(e,'Width',w); set(e,'Height',h)
        set(e,'CustomTextText',text); set(e,'CustomTextColor','FFFFFFFF')
        -- Optional presentation properties are used only if exposed by MA.
        if findProperty(e,'CustomTextSize') then set(e,'CustomTextSize',18) end
        if findProperty(e,'CustomTextAlignH') then set(e,'CustomTextAlignH','Center') end
        if findProperty(e,'CustomTextAlignV') then set(e,'CustomTextAlignV','Center') end
    end
    function self.install()
        self.preflight()
        local pluginHandle=plugin
        if type(plugin)=='function' then pluginHandle=plugin() end
        assert(pluginHandle,'Aufrufendes Plugin nicht gefunden')
        local pluginAddress=address(pluginHandle)
        save('scope',scope)
        save('complete',0)
        -- Build dependencies first; layout last. No macro is executed.
        for _,kind in ipairs({'Appearance','Macro','Layout'}) do
            for _,o in ipairs(plan.objects) do if o.kind==kind then
                local h=create(o)
                decorate(o,function()
                    set(h,'Name',o.label)
                    if kind=='Appearance' then
                        set(h,'BackR',tonumber(o.color:sub(2,3),16))
                        set(h,'BackG',tonumber(o.color:sub(4,5),16))
                        set(h,'BackB',tonumber(o.color:sub(6,7),16))
                        set(h,'BackAlpha',255)
                    elseif kind=='Macro' then
                        if not h[1] then command('Store '..address(h)..'.1 /NoConfirmation') end
                        local line=assert(h[1],'Makro-Zeile fehlt')
                        set(line,'Command',pluginAddress..' '..core.quote(o.action))
                        set(line,'Enabled','Yes'); set(line,'Execute','Yes'); set(line,'AddToCmdline','No')
                        command('Assign '..address(pools.Appearance[o.appearance])..' At '..address(h))
                    else
                        command('Assign '..address(pools.Appearance[config.appearance+11])..' At '..address(h))
                        local index=0
                        for _,macro in ipairs(plan.objects) do if macro.kind=='Macro' then
                            index=index+1
                            if not h[index] then
                                command('Assign '..address(pools.Macro[macro.id])..' At '..address(h))
                            end
                            local e=assert(h[index],'Makro-Zuweisung im Layout fehlt')
                            assert(e:GetAssignedObj()==pools.Macro[macro.id],'Falsche Layout-Zuweisung')
                            command('Assign '..address(pools.Appearance[macro.appearance])..' At '..address(e))
                            arrange(e,macro.x,macro.y,macro.width,macro.height,macro.label:sub(5))
                            set(e,'Action','Go+')
                        end end
                        local status=element(h,12)
                        arrange(status,0,130,640,110,'ZULETZT ANGEFORDERT: —')
                    end
                end)
            end end
        end
        save('complete',1)
        return plan
    end
    function self.uninstall()
        self.preflight() -- All owned/foreign checks complete before first delete.
        for _,kind in ipairs({'Layout','Macro','Appearance'}) do
            for _,o in ipairs(plan.objects) do if o.kind==kind then
                local h=object(o)
                if h then
                    assert(owned(o,h),'Objekt inzwischen verändert')
                    command('Delete '..address(h)..' /NoConfirmation')
                    assert(not object(o),'Objekt konnte nicht gelöscht werden')
                end
                save(key(o),'')
            end end
        end
        save('scope',''); save('complete',0)
    end
    function self.status(state)
        if read('scope')~=scope or tonumber(read('complete'))~=1 then return end
        local o={kind='Layout',id=config.layout}
        local h=object(o)
        assert(h and owned(o,h),'Status nicht geändert: Layout-Eigentumsnachweis fehlt')
        local destination=config.destination~='' and config.destination or 'Ziel in MA-OSC'
        set(assert(h[12]),'CustomTextText',
            'ZULETZT ANGEFORDERT: '..(state.lastAction or '—')..' '..(state.lastCue or '')..'\n'..
            'AUSWAHL: '..(state.selected or '—')..'  |  SONG: '..(state.song or '—')..'\n'..
            'OSC '..config.output..'  |  '..destination..':'..config.port)
    end
    return self
end
return M
