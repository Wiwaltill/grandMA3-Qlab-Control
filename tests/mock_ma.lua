-- Model of the MA adapter boundary, not a console emulator.
-- Command acceptance/property schema here cannot prove actual MA compatibility.
return function()
    local m={vars={},commands={},sets=0,dialogs={},nextId=0}
    local methods={}
    function methods:ToAddr() return self.address end
    function methods:Children()
        local out={}
        for i=1,10000 do if rawget(self,i) then out[#out+1]=self[i] end end
        return out
    end
    function methods:PropertyCount() return #self.schema end
    function methods:PropertyName(i) return self.schema[i+1] end
    function methods:Get(k) assert(self.allowed[k],'Unknown property '..k); return self.props[k] end
    function methods:Set(k,v)
        assert(self.allowed[k],'Unknown property '..k)
        if m.failProperty==k then error('Injected property failure: '..k) end
        self.props[k]=v; m.sets=m.sets+1
    end
    function methods:GetAssignedObj() return self.assigned end
    function m.node(address,kind)
        m.nextId=m.nextId+1
        local schemas={
            Pool={},Plugin={},
            Layout={'Name'}, Macro={'Name'},
            Appearance={'Name','BackR','BackG','BackB','BackAlpha'},
            Line={'Command','Enabled','Execute','AddToCmdline'},
            Element={'PosX','PosY','Width','Height','CustomTextText','CustomTextColor',
                'CustomTextSize','CustomTextAlignH','CustomTextAlignV','Action'}}
        local n=setmetatable({address=address,kind=kind,id='H#'..m.nextId,
            schema=assert(schemas[kind]),allowed={},props={}}, {__index=methods})
        for _,k in ipairs(n.schema) do n.allowed[k]=true end
        return n
    end
    local dp=m.node('DataPool 1','Pool')
    local show={}
    dp.Layouts=m.node('LayoutPool','Pool'); dp.Macros=m.node('MacroPool','Pool')
    show.Appearances=m.node('AppearancePool','Pool')
    m.dp=dp; m.show=show; m.plugin=m.node('Plugin 17','Plugin')
    local roots={LayoutPool=dp.Layouts,MacroPool=dp.Macros,AppearancePool=show.Appearances}
    local function resolve(address)
        local root=address:match('^[^%.]+'); local h=roots[root]
        if not h then return end
        for index in address:gmatch('%.(%d+)') do h=h[tonumber(index)]; if not h then return end end
        return h
    end
    function m.command(s)
        m.commands[#m.commands+1]=s
        if s:match('^SendOSC ') then return m.sendResult or 'OK' end
        local dest=s:match('^Store (.-) /NoConfirmation$')
        if dest then
            local pool,index=dest:match('^(%a+Pool) (%d+)$')
            if pool then dest=pool..'.'..index end
            local parent,index=dest:match('^(.*)%.(%d+)$'); index=tonumber(index)
            local h=assert(resolve(parent),'Unknown destination: '..dest)
            assert(not h[index],'Attempted overwrite')
            local kind=parent=='LayoutPool' and 'Layout' or parent=='MacroPool' and 'Macro' or
                parent=='AppearancePool' and 'Appearance' or h.kind=='Macro' and 'Line' or 'Element'
            h[index]=m.node(dest,kind); return 'OK'
        end
        local source,target=s:match('^Assign (.-) At (.+)$')
        if source then
            local h=assert(resolve(target)); local src=assert(resolve(source))
            if src.kind=='Macro' then
                local index=#h:Children()+1
                h[index]=m.node(target..'.'..index,'Element'); h[index].assigned=src
            else h.appearance=src end
            return 'OK'
        end
        dest=s:match('^Delete (.-) /NoConfirmation$')
        if dest then
            local parent,index=dest:match('^(.*)%.(%d+)$')
            assert(resolve(parent))[tonumber(index)]=nil; return 'OK'
        end
        error('Unexpected command: '..s)
    end
    m.api={GlobalVars=function() return m.vars end,
        DataPool=function() return m.dp end, ShowData=function() return m.show end,
        HandleToStr=function(h) return h.id end,
        -- MA may return auxiliary values. Callers must consume just the value.
        GetVar=function(vars,k) return vars[k],10 end,
        SetVar=function(vars,k,v) vars[k]=v; return true end,
        Cmd=m.command, Printf=function() end,
        MessageBox=function(box)
            m.dialogs[#m.dialogs+1]=box
            if m.respond then return m.respond(box) end
            return {success=true,result=1}
        end}
    return m
end
