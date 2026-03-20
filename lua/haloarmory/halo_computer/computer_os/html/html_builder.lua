-- HTML Builder Module - Provides utilities for building HTML in Lua
HALOARMORY.COMPUTER.INTERFACE.HTML = HALOARMORY.COMPUTER.INTERFACE.HTML or {}

local HTML = HALOARMORY.COMPUTER.INTERFACE.HTML

-- Create a new HTML builder instance
function HTML.NewBuilder()
    return {
        content = "",
        styles = {},
        scripts = {},
        
        -- Add raw HTML
        Add = function(self, html)
            self.content = self.content .. html
            return self
        end,
        
        -- Add CSS styles
        AddStyle = function(self, css)
            table.insert(self.styles, css)
            return self
        end,
        
        -- Add JavaScript
        AddScript = function(self, js)
            table.insert(self.scripts, js)
            return self
        end,
        
        -- Build the complete HTML document
        Build = function(self, title)
            local Timestamp = os.time()
            local TimeString = os.date( "%H:%M:%S - %d/%m/%Y" , Timestamp )
            title = title or "HALO Computer OS"
            local html = "<!DOCTYPE html>\n<html>\n<head>\n"
            html = html .. "<meta charset='UTF-8'>\n"
            html = html .. "<meta build_time='" .. TimeString .. "'>\n"
            html = html .. "<title>" .. title .. "</title>\n"
            html = html .. "<style>\n"
            html = html .. table.concat(self.styles, "\n")
            html = html .. "\n</style>\n"
            html = html .. "</head>\n<body>\n"
            html = html .. self.content
            html = html .. "<script>\n"
            html = html .. table.concat(self.scripts, "\n")
            html = html .. "\n</script>\n"
            html = html .. "</body>\n</html>"
            return html
        end
    }
end

-- Helper function to escape HTML
function HTML.Escape(str)
    if not str then return "" end
    return string.gsub(tostring(str), "[<>&\"']", {
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["&"] = "&amp;",
        ['"'] = "&quot;",
        ["'"] = "&#39;"
    })
end

-- Helper to generate CSS
function HTML.CSS(selector, rules)
    local css = selector .. " {\n"
    for key, value in pairs(rules) do
        css = css .. "    " .. key .. ": " .. tostring(value) .. ";\n"
    end
    css = css .. "}\n"
    return css
end

return HTML

