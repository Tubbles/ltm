-- eval: pure Lua expression evaluation per cursor selection. See
-- util.lua header for the dual-load design.

local M = {}

local function build_env()
    local env = {}
    -- `util` resolves at call time. In micro, ltm.util via the
    -- module() env. In busted, _G.util set by util.lua's load.
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

eval = M
return M
