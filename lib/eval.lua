local util = require("lib.util")

local M = {}

local function build_env()
    local env = {}
    util.flatten(env, math)
    setmetatable(env, {__index = _G})
    return env
end

local function clean_error(err)
    return (err:gsub('^%[string "[^"]*"%]:%d+:%s*', ""))
end

function M.eval(expr)
    local chunk, parse_err = loadstring("return (" .. expr .. ")")
    if not chunk then
        return nil, clean_error(parse_err)
    end
    setfenv(chunk, build_env())
    local ok, result = pcall(chunk)
    if not ok then
        return nil, clean_error(tostring(result))
    end
    return tostring(result), nil
end

return M
