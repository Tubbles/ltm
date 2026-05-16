-- dispatch: argument parser, op runner, and tab completer. See
-- util.lua header for the dual-load design. Cross-module references
-- to `convert`, `eval`, `seq`, `util` happen inside function bodies
-- and resolve at call time.

local M = {}

local CONVERT_OPS = {
    dec2hex = true, dec2oct = true, dec2bin = true,
    hex2dec = true, hex2oct = true, hex2bin = true,
    oct2dec = true, oct2hex = true, oct2bin = true,
    bin2dec = true, bin2hex = true, bin2oct = true,
}

local OP_NAMES_SORTED = {
    "bin2dec", "bin2hex", "bin2oct",
    "dec2bin", "dec2hex", "dec2oct",
    "eval",
    "hex2bin", "hex2dec", "hex2oct",
    "oct2bin", "oct2dec", "oct2hex",
    "seq",
}

local function known_op(name)
    if name == "eval" or name == "seq" then return true end
    return CONVERT_OPS[name] == true
end

function M.parse(args)
    if not args or #args == 0 then
        return nil, nil, "missing op (expected one of: " ..
            table.concat(OP_NAMES_SORTED, ", ") .. ")"
    end
    local op = args[1]
    if not known_op(op) then
        return nil, nil, "unknown op: " .. tostring(op)
    end

    if op == "eval" or CONVERT_OPS[op] then
        if #args > 1 then
            return nil, nil, op .. " takes no args"
        end
        return op, {}, nil
    end

    -- op == "seq"
    if #args < 3 then
        return nil, nil, "seq: missing args (need FIRST STEP [-z | -p])"
    end
    if #args > 4 then
        return nil, nil, "seq: too many args"
    end
    local first = tonumber(args[2])
    if first == nil then
        return nil, nil, "seq: FIRST is not a number: " .. tostring(args[2])
    end
    local step = tonumber(args[3])
    if step == nil then
        return nil, nil, "seq: STEP is not a number: " .. tostring(args[3])
    end
    local flag = nil
    if args[4] ~= nil then
        if args[4] == "-z" then
            flag = "z"
        elseif args[4] == "-p" then
            flag = "p"
        else
            return nil, nil, "seq: unknown flag: " .. tostring(args[4])
        end
    end
    return "seq", {first = first, step = step, flag = flag}, nil
end

function M.run(op, opargs, inputs, cursor_count)
    if op == "seq" then
        local outputs = seq.generate(opargs.first, opargs.step, cursor_count, opargs.flag)
        return outputs, nil
    end

    if op == "eval" then
        local outputs = {}
        for index = 1, cursor_count do
            local input = inputs[index]
            if input == nil or input == "" then
                outputs[index] = nil
            else
                local result, err = eval.eval(input)
                if err then
                    outputs[index] = err
                else
                    outputs[index] = result
                end
            end
        end
        return outputs, nil
    end

    if CONVERT_OPS[op] then
        local converter = convert[op]
        local outputs = {}
        for index = 1, cursor_count do
            outputs[index] = converter(inputs[index] or "")
        end
        return outputs, nil
    end

    return nil, "internal: unknown op in run: " .. tostring(op)
end

local function split_command_line(prefix)
    local parts = {}
    for part in (prefix .. " "):gmatch("([^ ]*) ") do
        parts[#parts + 1] = part
    end
    return parts
end

function M.complete(line, cursor_x)
    if not line then return {}, {} end
    local prefix = line:sub(1, cursor_x)
    local parts = split_command_line(prefix)
    local current = parts[#parts] or ""
    local position = #parts

    local suggestions = {}

    if position == 2 then
        for _, name in ipairs(OP_NAMES_SORTED) do
            if name:sub(1, #current) == current then
                suggestions[#suggestions + 1] = name
            end
        end
    elseif position == 5 and parts[2] == "seq" then
        if current == "" or current:sub(1, 1) == "-" then
            for _, flag in ipairs({"-p", "-z"}) do
                if flag:sub(1, #current) == current then
                    suggestions[#suggestions + 1] = flag
                end
            end
        end
    end

    local completions = {}
    for index, name in ipairs(suggestions) do
        completions[index] = name:sub(#current + 1)
    end

    return completions, suggestions
end

dispatch = M
return M
