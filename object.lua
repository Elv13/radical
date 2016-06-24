local setmetatable = setmetatable
local table        = table
local rawset       = rawset
local rawget       = rawget
local pairs        = pairs

local function setup_object(args)
    args = args or {}
    local data,signals = {},{}
    local private_data = args.private_data or {}
    
    function data:connect_signal(name,func)
        signals[name] = signals[name] or {}
        table.insert(signals[name],func)
        data:emit_signal("connection",name,#signals[name])
    end
    
    function data:disconnect_signal(name,func)
        for k,v in pairs(signals[name] or {}) do
            if v == func then
                signals[name][k] = nil
                data:emit_signal("disconnection",name,#signals[name])
            end
        end
    end
    
    function data:emit_signal(name,...)
        for k,v in pairs(signals[name] or {}) do
            v(data,...)
        end
    end
    
    function data:add_autosignal_field(name)
        args.force_private = args.force_private or {}
        table.insert(args.force_private,name)
    end
    
    local function return_data(tab, key)
        if rawget(tab,"get_"..key) then
            return rawget(tab,"get_"..key)(tab)
        elseif args.autogen_getmap == true and private_data[key] ~= nil then
            return private_data[key]
        elseif args.other_get_callback then
            local to_return = args.other_get_callback(key)
            if to_return then return to_return end
        end
        return rawget(tab,key)
    end
    
    local function auto_signal(key)
        if args.autogen_signals == true then
            data:emit_signal(key.."::changed")
        end
    end
    
    local function catch_changes(tab, key,value)
        local setter = rawget(tab,"set_"..key)
        if setter == false then
            --print("This is not a setter",debug.traceback()) --In some case, it may be called "normally", having this print is only good for debug
        elseif (data[key] ~= value or (args.always_handle ~= nil and args.always_handle[key] == true)) and setter then
            setter(tab,value)
            auto_signal(key)
        elseif (args.force_private or {})[key] == true or (args.autogen_setmap and (private_data[key] ~= nil)) then
            private_data[key] = value
            auto_signal(key)
        elseif setter == nil then
            rawset(data,key,value)
        end
        if args.auto_signal_changed == true then
            data:emit_signal("changed")
        end
    end
    
    setmetatable(data, { __index = return_data, __newindex = catch_changes, __len = function() return #data + #private_data end, })
    return data,private_data
end
return setmetatable({}, { __call = function(_, ...) return setup_object(...) end })
