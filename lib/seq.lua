local util = require("lib.util")

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

    local width = util.pad_width(raw)
    local padder = (flag == "z") and util.zero_pad or util.space_pad
    local padded = {}
    for index = 1, #raw do
        padded[index] = padder(raw[index], width)
    end
    return padded
end

return M
