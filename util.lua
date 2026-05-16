-- util: pure helpers reused by seq, convert, eval, dispatch.
--
-- This file is loaded two different ways:
--   1. By micro at plugin load time, where micro prepends
--      `module("ltm", package.seeall)` so the assignment to `util`
--      at the bottom lands on the ltm table.
--   2. By busted's `require("util")` for unit tests, where the
--      assignment becomes a global in _G and the `return M` gives
--      the spec a local binding via `local util = require("util")`.
--
-- The trick that makes one file work in both: don't `require` other
-- ltm modules at file load time. Micro's plugin loader has no
-- package.path entry that would find siblings. All cross-module
-- access happens inside function bodies (call time), after every
-- sibling has had a chance to set its global.

local M = {}

function M.flatten(into, from)
    for k, v in pairs(from) do
        if into[k] ~= nil then
            error("ltm: name collision while flattening: " .. tostring(k), 2)
        end
        into[k] = v
    end
    return into
end

function M.nonempty(s)
    local result = {}
    for line in (s .. "\n"):gmatch("([^\n]*)\n") do
        if line:match("%S") then
            result[#result + 1] = line
        end
    end
    return result
end

local PREFIX_FOR_BASE = {[16] = "0x", [8] = "0o", [2] = "0b"}

function M.strip_prefix(s, base)
    local prefix = PREFIX_FOR_BASE[base]
    if not prefix then
        return s
    end
    local sign, rest = s:match("^([%+%-]?)(.*)$")
    if rest:sub(1, 2):lower() == prefix then
        return sign .. rest:sub(3)
    end
    return s
end

function M.pad_width(strings)
    local width = 0
    for i = 1, #strings do
        local len = #strings[i]
        if len > width then
            width = len
        end
    end
    return width
end

function M.zero_pad(s, width)
    local sign, digits = s:match("^([%+%-]?)(.*)$")
    local pad = width - #s
    if pad <= 0 then
        return s
    end
    return sign .. string.rep("0", pad) .. digits
end

function M.space_pad(s, width)
    local pad = width - #s
    if pad <= 0 then
        return s
    end
    return string.rep(" ", pad) .. s
end

util = M
return M
