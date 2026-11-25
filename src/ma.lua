-- Runtime adapter. Unverified writes/transmission deliberately fail closed.
local M={}
function M.new(core, api)
    local self={}
    local prefix='QLC_V1_'
    local function read(key) return api.GetVar(api.GlobalVars(),prefix..key) end
    local function write(key,value)
        assert(api.SetVar(api.GlobalVars(),prefix..key,value), 'Could not persist '..key)
    end
    function self.load()
        local c={}
        for k in pairs(core.defaults) do c[k]=read(k) end
        return core.config(c)
    end
    function self.setup()
        local c=self.load()
        local inputs={}
        for _,k in ipairs({'destination','port','output','idle','blackout','layout','macro','appearance'}) do
            inputs[#inputs+1]={name=k,value=tostring(c[k])}
        end
        local r=api.MessageBox({title='QLab Control — Setup',
            message='Destination and port are metadata only. Configure MA OSC routing manually. No OSC is sent.',
            commands={{value=1,name='Save configuration'},{value=0,name='Cancel'}},inputs=inputs})
        if not r or not r.success or r.result~=1 then return end
        local valid=core.config(r.inputs)
        -- Validation completes before the first write. Persistence is not transactional.
        write('configured',0)
        for k,v in pairs(valid) do write(k,v) end
        write('configured',1)
        return valid
    end
    function self.select()
        local r=api.MessageBox({title='Select song cue',message='Numeric cue ID, including decimals.',
            commands={{value=1,name='Select'},{value=0,name='Cancel'}},
            inputs={{name='cue',value=read('selected') or ''}}})
        if r and r.success and r.result==1 then write('selected',core.cue(r.inputs.cue)) end
    end
    function self.plan()
        local p=core.plan(self.load())
        api.Printf('QLab Control: installation plan, %d objects; no pool changes.',#p.objects)
        for _,o in ipairs(p.objects) do api.Printf('%s %d: %s',o.kind,o.id,o.label) end
        return p
    end
    function self.run(argument)
        local command=core.parse(argument or 'SETUP')
        if command.action=='SETUP' then return self.setup() end
        if command.action=='PLAN' then return self.plan() end
        if command.action=='SELECT' then
            if command.cue then write('selected',command.cue); return end
            return self.select()
        end
        if command.action=='INSTALL' or command.action=='UPDATE' or command.action=='UNINSTALL' then
            error('Pool adapter pending verified 2.5.1.1 schema and ownership tests. PLAN is available.')
        end
        assert(tonumber(read('configured'))==1,'Save SETUP first')
        local confirmed=false
        if command.action=='PANIC' or command.action=='NEXT' or command.action=='TEST' then
            local messages={PANIC='Panic affects ALL cues in every workspace listening on this port. Confirm?',
                NEXT='GO uses the QLab playhead; it does not increment the selected cue. Confirm?',
                TEST='This test starts a real QLab cue. Confirm?'}
            local r=api.MessageBox({title=command.action,message=messages[command.action],
                commands={{value=1,name='Confirm'},{value=0,name='Cancel'}}})
            confirmed=r and r.success and r.result==1
            if not confirmed then return end
        end
        core.request(command,self.load(),{selected=read('selected'),song=read('song')},confirmed)
        error('OSC output disabled: argument-free SendOSC encoding requires a 2.5.1.1 smoke test. No OSC sent.')
    end
    return self
end
return M
