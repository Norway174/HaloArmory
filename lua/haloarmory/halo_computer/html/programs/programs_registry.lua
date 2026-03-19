-- Programs Registry - Central registry for all OS programs
HALOARMORY.COMPUTER.INTERFACE.PROGRAMS = HALOARMORY.COMPUTER.INTERFACE.PROGRAMS or {}

local PROGRAMS = HALOARMORY.COMPUTER.INTERFACE.PROGRAMS

-- Registry of all programs
PROGRAMS.registry = {}

-- Register a program
function PROGRAMS.Register(id, program)
    PROGRAMS.registry[id] = program
end

-- Get all registered programs
function PROGRAMS.GetAll()
    return PROGRAMS.registry
end

-- Generate JavaScript registry
function PROGRAMS.GetJavaScriptRegistry()
    local js = "var osPrograms = {\n"
    local first = true
    
    for id, program in pairs(PROGRAMS.registry) do
        if not first then
            js = js .. ",\n"
        end
        first = false
        
        local title = program.title or id
        local icon = program.icon or "📄"
        local content = (program.getContent and program.getContent()) or (program.content or "")
        local width = program.width or 600
        local height = program.height or 400
        
        js = js .. "    '" .. id .. "': {\n"
        js = js .. "        title: " .. string.format("%q", title) .. ",\n"
        js = js .. "        icon: " .. string.format("%q", icon) .. ",\n"
        js = js .. "        content: " .. string.format("%q", content) .. ",\n"
        js = js .. "        options: { width: " .. width .. ", height: " .. height .. " }"
        
        if program.getInitScript then
            js = js .. ",\n        init: function(windowId) {\n"
            js = js .. program.getInitScript() .. "\n"
            js = js .. "        }"
        elseif program.initScript then
            js = js .. ",\n        init: function(windowId) {\n"
            js = js .. program.initScript .. "\n"
            js = js .. "        }"
        end
        
        js = js .. "\n    }"
    end
    
    js = js .. "\n};\n\n"
    
    -- Create window.programRegistry API
    js = js .. [[
// Program Registry API
window.programRegistry = {
    getAll: function() {
        return osPrograms;
    },
    get: function(id) {
        return osPrograms[id];
    }
};
]]
    
    return js
end

return PROGRAMS

