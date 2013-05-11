local setmetatable = setmetatable
local table        = table
local rawset       = rawset
local rawget       = rawget
local pairs        = pairs

local function setup_object(args)
    local data,args,private_data,signals = {},args or {},private_data or {},{}
    local get_map,set_map,private_data = args.get_map or {},args.set_map or {},args.private_data or {}
    
    function data:connect_signal(name,func)
        signals[name] = signals[name] or {}
        table.insert(signals[name],func)
    end
    
    function data:remove_signal(name,func)
        for k,v in pairs(signals[name] or {}) do
            if v == func then
                signals[name][k] = nil
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
        if get_map[key] ~= nil then
            return get_map[key]()
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
        if set_map[key] == false then
            --print("This is not a setter",debug.traceback()) --In some case, it may be called "normally", having this print is only good for debug
        elseif (data[key] ~= value or (args.always_handle ~= nil and args.always_handle[key] == true)) and set_map[key] ~= nil then
            set_map[key](value)
            auto_signal(key)
        elseif (args.force_private or {})[key] == true or (args.autogen_setmap and (private_data[key] ~= nil)) then
            private_data[key] = value
            auto_signal(key)
        elseif set_map[key] == nil then
            rawset(data,key,value)
        end
        if args.auto_signal_changed == true then
            data:emit_signal("changed")
        end
    end
    
    setmetatable(data, { __index = return_data, __newindex = catch_changes, __len = function() return #data + #private_data end, })
    return data,set_map,get_map,private_data
end
return setmetatable({}, { __call = function(_, ...) return setup_object(...) end })