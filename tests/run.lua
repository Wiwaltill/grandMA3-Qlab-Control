local core=dofile('src/core.lua')
local ma=dofile('src/ma.lua')
local guide=dofile('src/guide.lua')
local count=0
local function test(name,fn)
    local ok,err=pcall(fn)
    assert(ok,name..': '..tostring(err)); count=count+1
end
local function rejects(fn) assert(not pcall(fn),'Expected rejection') end
local config=core.config({})
test('string cue identifiers',function()
    for _,id in ipairs({'001','101.20','0','900'}) do assert(core.parse('START '..id).cue==id) end
end)
test('reject injection and malformed cues',function()
    for _,s in ipairs({'START 1; Delete Macro 1','START 1/stop','START 1,1','START 1 2',
        'START101','START -1','START 1.','START .1','START 1.2.3','START "1"','START selected',
        'UNKNOWN 1','PANIC 1','SETUP 1','START 1\nSTOP'}) do rejects(function() core.parse(s) end) end
end)
test('configuration limits',function()
    for k,v in pairs({port=65536,output=0,macro=9989,appearance=9989,layout=-1,idle='x',destination='host;bad'}) do
        rejects(function() core.config({[k]=v}) end)
    end
end)
test('quote safety',function()
    assert(core.quote('START 101.2')=='"START 101.2"')
    for _,s in ipairs({'a"b','a;b','a\\b','a\nb'}) do rejects(function() core.quote(s) end) end
end)
test('transport and immutable state',function()
    local state={selected='101.20',song='100'}
    for action,verb in pairs({START='start',PAUSE='pause',STOP='stop',RESUME='resume'}) do
        local messages,nextState=core.request(core.parse(action),config,state)
        assert(messages[1].address=='/cue/101.20/'..verb and #messages[1].arguments==0)
        assert(state.song=='100' and state.lastAction==nil)
        assert(nextState.lastCue=='101.20')
    end
end)
test('graphics preserve song and selection',function()
    local _,song=core.request(core.parse('START 101.2'),config,{})
    local messages,graphic=core.request(core.parse('IDLE'),config,song)
    assert(messages[1].address=='/cue/900/start')
    assert(graphic.song=='101.2' and graphic.selected=='101.2' and graphic.lastCue=='900')
    local stop=core.request(core.parse('STOP'),config,graphic)
    assert(stop[1].address=='/cue/101.2/stop')
end)
test('manual and destructive actions require confirmation',function()
    for _,action in ipairs({'NEXT','PANIC','TEST 999'}) do
        rejects(function() core.request(core.parse(action),config,{}) end)
        local messages=core.request(core.parse(action),config,{},true)
        assert(#messages==1)
    end
    rejects(function() core.request(core.parse('RESTART 1'),config,{}) end)
    rejects(function() core.request(core.parse('START'),config,{}) end)
end)
test('layout plan has distinct slots and required ordering',function()
    local p=core.plan(config); assert(#p.objects==24)
    local seen={}
    for _,o in ipairs(p.objects) do
        local key=o.kind..o.id; assert(not seen[key]); seen[key]=true
    end
    assert(core.buttons[6][2]=='NEXT' and core.buttons[7][1]=='PAUSENGRAFIK')
    assert(p.status.text=='ZULETZT ANGEFORDERT: —')
end)
test('full preflight rejects foreign or replaced objects',function()
    local p=core.plan(config)
    assert(core.preflight(p,{inspect=function() return nil end}))
    local api={inspect=function(kind,id) if kind=='Macro' and id==511 then return 'foreign' end end}
    rejects(function() core.preflight(p,api) end)
    assert(core.preflight(p,api,{['Macro:511']='foreign'}))
    rejects(function() core.preflight(p,api,{['Macro:511']='old identity'}) end)
end)
local function uiValues(c)
    return {['01 QLab-Ziel (IP, optional)']=c.destination,
        ['02 QLab-OSC-Port']=tostring(c.port), ['03 MA-OSC-Zeilennummer']=tostring(c.output),
        ['04 Pausengrafik-Cue']=c.idle, ['05 Schwarzbild-Cue']=c.blackout,
        ['06 Layout-Nummer']=tostring(c.layout), ['07 Erste Makro-Nummer']=tostring(c.macro),
        ['08 Erste Appearance-Nummer']=tostring(c.appearance)}
end
local function mock(result)
    local vars={}; local writes=0
    return {GlobalVars=function() return vars end,
        GetVar=function(v,k) return v[k] end,
        SetVar=function(v,k,value) v[k]=value; writes=writes+1; return true end,
        MessageBox=function() return result end,
        Printf=function() end,
        Cmd=function() error('Unexpected command execution') end},vars,function() return writes end
end
test('setup saves only validated configuration',function()
    local api,vars=mock({success=true,result=1,inputs=uiValues(config)})
    ma.new(core,api,guide).run('SETUP')
    assert(vars.QLC_V1_configured==1 and vars.QLC_V1_output==1)
end)
test('setup cancel and invalid input never write',function()
    for _,r in ipairs({{success=true,result=0},{success=true,result=1,inputs={['02 QLab-OSC-Port']='invalid'}}}) do
        local api,_,writes=mock(r)
        pcall(function() ma.new(core,api,guide).run('SETUP') end)
        assert(writes()==0)
    end
end)
test('plan and lifecycle gates never execute MA commands',function()
    local api,_,writes=mock(nil); local adapter=ma.new(core,api,guide)
    adapter.run('PLAN'); assert(writes()==0)
    for _,a in ipairs({'INSTALL','UPDATE','UNINSTALL','START 1'}) do rejects(function() adapter.run(a) end) end
    assert(writes()==0)
end)
test('configured transport fails closed without changing state',function()
    local api,vars,writes=mock({success=true,result=1,inputs=uiValues(config)})
    local adapter=ma.new(core,api,guide); adapter.run('SETUP')
    local before=writes()
    for _,a in ipairs({'START 1','PANIC','NEXT','TEST 999'}) do rejects(function() adapter.run(a) end) end
    assert(writes()==before and vars.QLC_V1_song==nil)
end)
test('German labels map to stable storage and preserve old values',function()
    local c=core.config({destination='qlab.local',port=53100,output=4,idle='0900.20',blackout='901.2',
        macro=600,appearance=700,layout=300})
    local api,vars=mock({success=true,result=1,inputs=uiValues(c)})
    ma.new(core,api,guide).run('SETUP')
    for k,v in pairs(c) do assert(vars['QLC_V1_'..k]==v) end
    local original=api.MessageBox
    api.MessageBox=function(box)
        assert(box.title=='QLab Control '..core.version..' — Einstellungen')
        assert(#box.inputs==8 and box.inputs[1].value=='qlab.local')
        assert(box.inputs[3].value=='4')
        return {success=true,result=0}
    end
    ma.new(core,api,guide).run('SETUP')
end)
test('German cue selection preserves decimal strings',function()
    local api,vars=mock({success=true,result=1,inputs={['Cue-Nummer']='001.20'}})
    ma.new(core,api,guide).run('SELECT')
    assert(vars.QLC_V1_selected=='001.20')
end)
test('OSC help works before setup and never writes',function()
    local api,_,writes=mock(nil)
    local seen=false
    api.MessageBox=function(box)
        assert(box.title:find('OSC%-Anleitung  |  1 / 5'))
        assert(box.message:find('OSC / UDP') and box.backColor=='Window.Plugins')
        seen=true
    end
    ma.new(core,api,guide).run('OSCHELP')
    assert(seen and writes()==0)
    rejects(function() core.parse('OSCHELP 1') end)
end)
test('OSC help button does not save setup or transmit',function()
    local api,_,writes=mock(nil); local calls=0
    api.MessageBox=function(box)
        calls=calls+1
        if calls==1 then
            assert(box.commands[2].name=='OSC-Anleitung')
            return {success=true,result=2}
        end
        assert(box.title:find('OSC%-Anleitung  |  1 / 5'))
    end
    ma.new(core,api,guide).run('SETUP')
    assert(calls==2 and writes()==0)
end)
test('guide forward/back navigation and exit never mutate settings',function()
    local api,vars,writes=mock(nil)
    vars.QLC_V1_port=53100; vars.QLC_V1_output=4; vars.QLC_V1_destination='qlab.local'
    local path={1,2,3,2,3,4,5}
    local choices={2,2,1,2,2,2,0}
    local calls=0
    api.MessageBox=function(box)
        calls=calls+1
        assert(box.title:find(path[calls]..' / 5',1,true))
        assert(box.inputs==nil and box.states==nil and box.timeout==nil)
        if path[calls]==1 then assert(#box.commands==2) end
        if path[calls]==5 then
            assert(#box.commands==2)
            assert(box.message:find('53100') and box.message:find('qlab.local',1,true))
            assert(box.message:find('MA%-Zeile 4'))
        end
        return {success=true,result=choices[calls]}
    end
    ma.new(core,api,guide).run('OSCHELP')
    assert(calls==#path and writes()==0)
end)
test('guide cancellation and reopening start at overview',function()
    local api,_,writes=mock(nil); local calls=0
    api.MessageBox=function(box)
        calls=calls+1; assert(box.title:find('1 / 5',1,true))
        return {success=false}
    end
    local adapter=ma.new(core,api,guide)
    adapter.run('OSCHELP'); adapter.run('OSCHELP')
    assert(calls==2 and writes()==0)
end)
print(count..' Lua test groups passed')
