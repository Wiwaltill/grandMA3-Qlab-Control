local core=dofile('src/core.lua')
local ma=dofile('src/ma.lua')
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
    assert(p.status.text=='LAST REQUESTED: —')
end)
test('full preflight rejects foreign or replaced objects',function()
    local p=core.plan(config)
    assert(core.preflight(p,{inspect=function() return nil end}))
    local api={inspect=function(kind,id) if kind=='Macro' and id==511 then return 'foreign' end end}
    rejects(function() core.preflight(p,api) end)
    assert(core.preflight(p,api,{['Macro:511']='foreign'}))
    rejects(function() core.preflight(p,api,{['Macro:511']='old identity'}) end)
end)
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
    local api,vars=mock({success=true,result=1,inputs=config})
    ma.new(core,api).run('SETUP')
    assert(vars.QLC_V1_configured==1 and vars.QLC_V1_output==1)
end)
test('setup cancel and invalid input never write',function()
    for _,r in ipairs({{success=true,result=0},{success=true,result=1,inputs={port='invalid'}}}) do
        local api,_,writes=mock(r)
        pcall(function() ma.new(core,api).run('SETUP') end)
        assert(writes()==0)
    end
end)
test('plan and lifecycle gates never execute MA commands',function()
    local api,_,writes=mock(nil); local adapter=ma.new(core,api)
    adapter.run('PLAN'); assert(writes()==0)
    for _,a in ipairs({'INSTALL','UPDATE','UNINSTALL','START 1'}) do rejects(function() adapter.run(a) end) end
    assert(writes()==0)
end)
test('configured transport fails closed without changing state',function()
    local api,vars,writes=mock({success=true,result=1,inputs=config})
    local adapter=ma.new(core,api); adapter.run('SETUP')
    local before=writes()
    for _,a in ipairs({'START 1','PANIC','NEXT','TEST 999'}) do rejects(function() adapter.run(a) end) end
    assert(writes()==before and vars.QLC_V1_song==nil)
end)
print(count..' Lua test groups passed')
