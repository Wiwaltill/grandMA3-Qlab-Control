local core=dofile('src/core.lua')
local pools=dofile('src/pools.lua')
local ma=dofile('src/ma.lua')
local guide=dofile('src/guide.lua')
local mock=dofile('tests/mock_ma.lua')
local config=core.config({})
local count=0
local function test(name,fn)
    local ok,err=pcall(fn); assert(ok,name..': '..tostring(err)); count=count+1
end
local function rejects(fn) assert(not pcall(fn),'Expected rejection') end
local function adapter(m,c) return pools.new(core,m.api,c or config,m.plugin) end
local function configured(m)
    for k,v in pairs(config) do m.vars['QLC_V1_'..k]=v end
    m.vars.QLC_V1_configured=1
    return ma.new(core,m.api,guide,pools,m.plugin)
end
local function noOSC(m)
    for _,s in ipairs(m.commands) do assert(not s:match('^SendOSC')) end
end
test('full install creates 24 objects and functional macro/layout bindings',function()
    local m=mock(); adapter(m).install()
    assert(m.commands[1]=='Store AppearancePool 501 /NoConfirmation')
    assert(#m.dp.Macros:Children()==11 and #m.show.Appearances:Children()==12)
    local h=m.dp.Layouts[200]; assert(#h:Children()==12)
    assert(m.dp.Macros[501][1]:Get('Command')=='Plugin 17 "START"')
    assert(h[1].assigned==m.dp.Macros[501] and h[11].assigned==m.dp.Macros[511])
    assert(h[1]:Get('Width')=='200' and h[10]:Get('Width')=='310')
    assert(m.show.Appearances[501]:Get('BackR')==tostring(0x27))
    noOSC(m)
end)
test('install update and cleanup preserve unrelated objects',function()
    local m=mock(); local foreign=m.node('MacroPool.10','Macro'); m.dp.Macros[10]=foreign
    local a=adapter(m); a.install(); local first=m.dp.Macros[501]
    a.install(); assert(m.dp.Macros[501]==first and #m.dp.Layouts[200]:Children()==12)
    a.uninstall()
    assert(m.dp.Macros[10]==foreign and #m.dp.Macros:Children()==1)
    assert(#m.dp.Layouts:Children()==0 and #m.show.Appearances:Children()==0)
    noOSC(m)
end)
test('late-slot conflict prevents every mutation',function()
    for _,kind in ipairs({'Layout','Macro','Appearance'}) do
        local m=mock(); local pool=kind=='Layout' and m.dp.Layouts or kind=='Macro' and m.dp.Macros or m.show.Appearances
        local id=kind=='Layout' and 200 or kind=='Macro' and 511 or 512
        pool[id]=m.node('foreign',kind)
        rejects(function() adapter(m).install() end)
        assert(#m.commands==0 and m.sets==0 and next(m.vars)==nil)
    end
end)
test('same label replacement and foreign child block update and all cleanup',function()
    for _,tamper in ipairs({'replace','child'}) do
        local m=mock(); local a=adapter(m); a.install()
        if tamper=='replace' then
            m.dp.Macros[511]=m.node('MacroPool.511','Macro')
            m.dp.Macros[511]:Set('Name','QLC EINSTELLUNGEN')
        else m.dp.Layouts[200][13]=m.node('LayoutPool.200.13','Element') end
        local before=#m.commands; local sets=m.sets
        rejects(function() a.install() end); rejects(function() a.uninstall() end)
        assert(#m.commands==before and m.sets==sets)
    end
end)
test('partial install can resume or safely uninstall',function()
    for _,resume in ipairs({true,false}) do
        local m=mock(); m.failProperty='Command'
        rejects(function() adapter(m).install() end)
        assert(m.vars.QLC_V1_owned_complete==0)
        assert(m.dp.Macros[501] and m.dp.Macros[501][1])
        m.failProperty=nil
        if resume then adapter(m).install(); assert(m.vars.QLC_V1_owned_complete==1)
        else adapter(m).uninstall(); assert(#m.dp.Macros:Children()==0) end
        noOSC(m)
    end
end)
test('changed data pool and changed ranges fail closed',function()
    local m=mock(); adapter(m).install()
    local before=#m.commands
    rejects(function() adapter(m,core.config({macro=600})).install() end)
    m.dp.id='other-pool'
    rejects(function() adapter(m).uninstall() end)
    assert(#m.commands==before)
end)
test('explicit OSC test sends exactly once after confirmation',function()
    local m=mock(); local app=configured(m); app.run('INSTALL'); noOSC(m)
    app.run('TEST 101.20')
    assert(m.commands[#m.commands]=='SendOSC 1 "/cue/101.20/start"')
    local sent=0; for _,s in ipairs(m.commands) do if s:match('^SendOSC') then sent=sent+1 end end
    assert(sent==1 and m.vars.QLC_V1_lastAction=='TEST' and m.vars.QLC_V1_lastCue=='101.20')
    assert(m.vars.QLC_V1_song=='' and m.vars.QLC_V1_selected=='')
    assert(m.dp.Layouts[200][12]:Get('CustomTextText'):find('TEST 101.20',1,true))
end)
test('cancel or invalid OSC test does not send or change state',function()
    local m=mock(); local app=configured(m)
    m.respond=function() return {success=true,result=0} end
    app.run('TEST 1'); app.run('TEST'); app.run('PANIC'); app.run('NEXT')
    rejects(function() app.run('TEST 1;Delete') end)
    assert(#m.commands==0 and m.vars.QLC_V1_lastAction==nil)
end)
test('OSC rejection never records success or retries',function()
    local m=mock(); local app=configured(m); m.sendResult='Syntax Error'
    rejects(function() app.run('TEST 1') end)
    assert(#m.commands==1 and m.vars.QLC_V1_lastAction==nil)
end)
test('transport targets song after graphic and panic is explicit',function()
    local m=mock(); local app=configured(m)
    app.run('START 101.2'); app.run('IDLE'); app.run('STOP')
    assert(m.commands[1]=='SendOSC 1 "/cue/101.2/start"')
    assert(m.commands[2]=='SendOSC 1 "/cue/900/start"')
    assert(m.commands[3]=='SendOSC 1 "/cue/101.2/stop"')
    app.run('PANIC'); assert(m.commands[4]=='SendOSC 1 "/panic"')
    assert(m.vars.QLC_V1_lastCue=='' and m.vars.QLC_V1_song=='101.2')
end)
test('test dialog requires a cue then a distinct confirmation',function()
    local m=mock(); local app=configured(m); local calls=0
    m.respond=function(box)
        calls=calls+1
        if calls==1 then return {success=true,result=1,inputs={['Test-Cue']='999.2'}} end
        return {success=true,result=1}
    end
    app.run('TEST'); assert(calls==3 and #m.commands==1)
    assert(m.commands[1]=='SendOSC 1 "/cue/999.2/start"')
end)
test('OSC construction rejects payload injection and non-whitelisted actions',function()
    for _,address in ipairs({'/cue/1/reset','/cue/selected/start','/cue/1/start,s,x','/cue/1/start";Delete'}) do
        rejects(function() core.oscCommand(1,{address=address,arguments={}}) end)
    end
    rejects(function() core.oscCommand('1;Delete',{address='/go',arguments={}}) end)
    rejects(function() core.oscCommand(1,{address='/go',arguments={'dummy'}}) end)
end)
test('installed transport refuses a different data pool',function()
    local m=mock(); local app=configured(m); app.run('INSTALL')
    local before=#m.commands
    m.dp.id='different-pool'
    rejects(function() app.run('START 1') end)
    assert(#m.commands==before and m.vars.QLC_V1_lastAction==nil)
end)
test('uninstall cancel leaves all pool objects unchanged',function()
    local m=mock(); local app=configured(m); app.run('INSTALL')
    local before=#m.commands
    m.respond=function() return {success=true,result=0} end
    app.run('UNINSTALL')
    assert(#m.commands==before and m.dp.Layouts[200]~=nil)
end)
test('unavailable MA properties journal a resumable partial install',function()
    local m=mock(); m.failProperty='CustomTextText'
    rejects(function() adapter(m).install() end)
    assert(m.vars.QLC_V1_owned_complete==0 and m.dp.Layouts[200])
    m.failProperty=nil; adapter(m).uninstall()
    assert(#m.dp.Layouts:Children()==0); noOSC(m)
end)
test('generated component dispatches install and test with its own plugin handle',function()
    local m=mock(); configured(m)
    local errors={}; m.api.ErrPrintf=function(_,err) errors[#errors+1]=err end
    local previous={}
    for k,v in pairs(m.api) do previous[k]=_G[k]; _G[k]=v end
    local ok,err=pcall(function()
        local component={Parent=function() return m.plugin end}
        local entry=assert(loadfile('dist/QLab Control.lua'))('QLab Control','main',{},component)
        entry(nil,'INSTALL'); entry(nil,'TEST 999.20')
        assert(#errors==0,table.concat(errors,'; '))
        assert(m.dp.Layouts[200] and m.vars.QLC_V1_lastCue=='999.20')
        assert(m.commands[#m.commands]=='SendOSC 1 "/cue/999.20/start"')
    end)
    for k in pairs(m.api) do _G[k]=previous[k] end
    assert(ok,err)
end)
print(count..' pool/transport integration test groups passed (mocked MA)')
