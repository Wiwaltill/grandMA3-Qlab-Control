-- Pure Lua: no grandMA globals, I/O, or network access.
local M = {version = '0.1.0-dev.1'}
local transport = {START='start', STOP='stop', PAUSE='pause', RESUME='resume'}
local special = {IDLE='idle', BLACKOUT='blackout'}
local other = {SETUP=true, SELECT=true, NEXT=true, PANIC=true, RESTART=true,
    PLAN=true, INSTALL=true, UPDATE=true, UNINSTALL=true, TEST=true}

function M.cue(s)
    assert(type(s)=='string' and #s<=64 and
        (s:match('^%d+$') or s:match('^%d+%.%d+$')), 'Cue must be a numeric string, e.g. 101.2')
    return s -- Never convert to a number: preserve 001 and 101.20.
end

function M.parse(s)
    assert(type(s)=='string' and #s<=128, 'Invalid command')
    local trimmed=s:match('^%s*(.-)%s*$')
    local action, tail = trimmed:match('^([A-Za-z]+)%s+(.+)$')
    if not action then action=trimmed:match('^([A-Za-z]+)$'); tail='' end
    assert(action, 'Expected ACTION [cue]')
    action = action:upper()
    assert(transport[action] or special[action] or other[action], 'Unknown action')
    local id = tail~='' and M.cue(tail) or nil
    assert(not id or transport[action] or action=='SELECT' or action=='RESTART' or action=='TEST',
        'This action does not accept a cue')
    return {action=action, cue=id}
end

local function integer(v, lo, hi)
    local s=tostring(v)
    assert(s:match('^%d+$'), 'Expected positive integer')
    local n=tonumber(s)
    assert(n>=lo and n<=hi, 'Integer out of range')
    return n
end

M.defaults = {destination='', port=53000, output=1, idle='900', blackout='901',
    layout=200, macro=501, appearance=501}
function M.config(values)
    local c={}
    for k,v in pairs(M.defaults) do c[k]=values[k]~=nil and values[k] or v end
    assert(type(c.destination)=='string' and #c.destination<=253 and
        not c.destination:find('[^%w%.%-]'), 'Destination metadata must be a host name or IPv4 address')
    c.port=integer(c.port,1,65535)
    c.output=integer(c.output,1,9999)
    c.layout=integer(c.layout,1,9999)
    c.macro=integer(c.macro,1,9988)
    c.appearance=integer(c.appearance,1,9988)
    c.idle=M.cue(c.idle); c.blackout=M.cue(c.blackout)
    return c
end

-- Values used in MA commands must never introduce syntax.
function M.quote(s)
    assert(type(s)=='string' and not s:find('[%c"\\;]'), 'Unsafe MA string')
    return '"'..s..'"'
end

-- Native layout specification, independent of the runtime property schema.
M.buttons = {
    {'START','START','#27884A'}, {'PAUSE','PAUSE','#C68C24'}, {'STOP','STOP','#B52F35'},
    {'RESTART','RESTART','#526176'}, {'RESUME','RESUME','#27884A'}, {'NEXT CUE','NEXT','#526176'},
    {'PAUSENGRAFIK','IDLE','#286DA8'}, {'BLACKOUT','BLACKOUT','#101010'}, {'PANIC','PANIC','#B52F35'},
    {'SELECT CUE','SELECT','#646464'}, {'SETUP','SETUP','#646464'}
}

function M.plan(config)
    local c=M.config(config)
    local p={background='#171717', objects={}}
    local function add(kind,id,label,extra)
        local o={kind=kind,id=id,label=label}
        for k,v in pairs(extra or {}) do o[k]=v end
        p.objects[#p.objects+1]=o
    end
    add('Layout',c.layout,'QLC Layout')
    for i,b in ipairs(M.buttons) do
        local x,y=((i-1)%3)*220,-math.floor((i-1)/3)*110
        if i>=10 then x=(i-10)*330 end
        add('Appearance',c.appearance+i-1,'QLC '..b[2],{color=b[3]})
        add('Macro',c.macro+i-1,'QLC '..b[1],{action=b[2],appearance=c.appearance+i-1,
            x=x,y=y,width=i>=10 and 310 or 200,height=90})
    end
    add('Appearance',c.appearance+11,'QLC Status',{color='#171717'})
    p.status={text='LAST REQUESTED: —',selected='SELECTED CUE: —',song='LAST SONG: —',
        output=c.output,destination=c.destination,port=c.port,x=0,y=130,width=640,height=100}
    return p
end

-- Adapter contract: inspect(kind,id) -> immutable identity or nil.
-- Ownership requires an external manifest plus exact identity, never a label alone.
function M.preflight(plan, adapter, manifest)
    for _,o in ipairs(plan.objects) do
        local identity=adapter.inspect(o.kind,o.id)
        local key=o.kind..':'..o.id
        assert(not identity or (manifest and manifest[key]==identity), 'Pool conflict: '..key)
    end
    return true
end

-- Produces semantic OSC messages only; wire encoding belongs to the adapter.
-- State is returned separately and committed only after adapter acceptance.
function M.request(command, config, state, confirmed)
    local a=command.action
    local nextState={}
    for k,v in pairs(state) do nextState[k]=v end
    local target=command.cue or state.selected or state.song
    if a=='SELECT' then
        nextState.selected=M.cue(assert(command.cue,'SELECT requires a cue'))
        return {},nextState
    end
    if a=='RESTART' then
        error('RESTART pending verified QLab cue/group semantics; use an explicit QLab restart cue')
    end
    local address
    if transport[a] then
        target=M.cue(assert(target,'Select a song cue first'))
        address='/cue/'..target..'/'..transport[a]
        nextState.selected=target
        if a=='START' then nextState.song=target end
    elseif special[a] then
        target=M.cue(config[special[a]])
        address='/cue/'..target..'/start'
    elseif a=='TEST' then
        assert(confirmed, 'TEST requires explicit confirmation')
        target=M.cue(assert(command.cue,'TEST requires a dedicated test cue'))
        address='/cue/'..target..'/start'
    elseif a=='NEXT' then
        assert(confirmed, 'NEXT requires playhead warning confirmation')
        address='/go'; target=nil
    elseif a=='PANIC' then
        assert(confirmed, 'PANIC requires confirmation')
        address='/panic'; target=nil
    else error('Action is not a transport request') end
    nextState.lastAction=a; nextState.lastCue=target
    return {{address=address,arguments={}}},nextState
end
return M
