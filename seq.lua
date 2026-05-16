-- seq: arithmetic sequence generator with sign-aware padding.
-- See util.lua header for the dual-load design.

local M = {}

function M.generate(first, step, count, flag)
    if flag ~= nil and flag ~= "z" and flag ~= "p" then
        error("ltm seq: unknown flag: " .. tostring(flag), 2)
    end

    local raw = {}
    for index = 0, count - 1 do
        raw[index + 1] = tostring(first + index * step)
    end

    if flag == nil then
        return raw
    end

    -- `util` resolves at call time: in micro it's ltm.util (set by
    -- util.lua's `util = M`); in busted it's _G.util.
    local width = util.pad_width(raw)
    local padder = (flag == "z") and util.zero_pad or util.space_pad
    local padded = {}
    for index = 1, #raw do
        padded[index] = padder(raw[index], width)
    end
    return padded
end

seq = M
return M
