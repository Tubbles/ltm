local util = require("lib.util")

local M = {}

local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"

local DIGIT_PATTERN = {
    [2]  = "^[01]+$",
    [8]  = "^[0-7]+$",
    [10] = "^[0-9]+$",
    [16] = "^[0-9a-fA-F]+$",
}

local function format_unsigned(value, base)
    if value == 0 then
        return "0"
    end
    local digits = {}
    while value > 0 do
        local digit = value % base
        digits[#digits + 1] = DIGITS:sub(digit + 1, digit + 1)
        value = math.floor(value / base)
    end
    for index = 1, math.floor(#digits / 2) do
        local mirror = #digits - index + 1
        digits[index], digits[mirror] = digits[mirror], digits[index]
    end
    return table.concat(digits)
end

local function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function M.apply(from_base, to_base, sel)
    if sel == "" then
        return nil
    end

    local stripped = trim(sel)
    if stripped == "" then
        return nil
    end

    local sign = ""
    local head = stripped:sub(1, 1)
    if head == "-" then
        sign = "-"
        stripped = stripped:sub(2)
    elseif head == "+" then
        stripped = stripped:sub(2)
    end

    stripped = util.strip_prefix(stripped, from_base)

    if not stripped:match(DIGIT_PATTERN[from_base]) then
        return "nil"
    end

    local value = tonumber(stripped, from_base)
    if value == nil then
        return "nil"
    end
    if sign == "-" then
        value = -value
    end

    if value < 0 then
        return "-" .. format_unsigned(-value, to_base)
    end
    return format_unsigned(value, to_base)
end

function M.dec2hex(sel) return M.apply(10, 16, sel) end
function M.dec2oct(sel) return M.apply(10,  8, sel) end
function M.dec2bin(sel) return M.apply(10,  2, sel) end
function M.hex2dec(sel) return M.apply(16, 10, sel) end
function M.hex2oct(sel) return M.apply(16,  8, sel) end
function M.hex2bin(sel) return M.apply(16,  2, sel) end
function M.oct2dec(sel) return M.apply( 8, 10, sel) end
function M.oct2hex(sel) return M.apply( 8, 16, sel) end
function M.oct2bin(sel) return M.apply( 8,  2, sel) end
function M.bin2dec(sel) return M.apply( 2, 10, sel) end
function M.bin2hex(sel) return M.apply( 2, 16, sel) end
function M.bin2oct(sel) return M.apply( 2,  8, sel) end

return M
