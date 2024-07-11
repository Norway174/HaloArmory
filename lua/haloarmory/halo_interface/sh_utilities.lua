HALOARMORY.MsgC("Shared INTERFACE Utilities Loaded!")


HALOARMORY.INTERFACE = HALOARMORY.INTERFACE or {}


// Pretty format a number with a custom delimiter. If the delimiter is not specified, it will default to a comma.
function HALOARMORY.INTERFACE.PrettyFormatNumber(number, delimiter)
    if not delimiter then
        delimiter = ","
    end

    if not isnumber(number) then return 0 end

    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')

    if not int then return 0 end

    -- reverse the int-string and append a comma to all blocks of 3 digits
    int = int:reverse():gsub("(%d%d%d)", "%1" .. delimiter)
  
    -- reverse the int-string back remove an optional comma and put the 
    -- optional minus and fractional part back
    return minus .. int:reverse():gsub("^,", "") .. fraction
end