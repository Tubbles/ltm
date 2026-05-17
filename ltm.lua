VERSION = "0.1.0"

-- ltm: text transforms over multi-cursor selections.
--
-- This file is the only one that touches micro's plugin APIs. The
-- pure modules (util, seq, convert, eval, dispatch) live in sibling
-- top-level .lua files and are loaded automatically by micro at
-- plugin init time. See util.lua's header for the load model.
--
-- Cross-module references resolve at call time: by the moment
-- `run()` or `complete()` fires (i.e. when the user invokes the
-- command or presses Tab), every sibling has loaded and set its
-- module table on the shared ltm namespace.

local micro      = import("micro")
local config     = import("micro/config")
local micro_util = import("micro/util")

local function apply_edits(bp, cursors, has_sel, outputs)
    -- Build edit records before applying any of them. The cursor
    -- list `cursors` may come back from GetCursors() in arbitrary
    -- order, so we sort by stored start position descending and
    -- apply later edits first. That keeps earlier-stored Locs valid
    -- through the loop because a later edit doesn't shift any
    -- earlier position.
    local edits = {}
    for index = 1, #cursors do
        local output = outputs[index]
        if output ~= nil then
            local cursor = cursors[index]
            if has_sel[index] then
                edits[#edits + 1] = {
                    kind  = "replace",
                    start = -cursor.CurSelection[1],
                    stop  = -cursor.CurSelection[2],
                    text  = output,
                }
            else
                edits[#edits + 1] = {
                    kind  = "insert",
                    start = -cursor.Loc,
                    text  = output,
                }
            end
        end
    end

    table.sort(edits, function(a, b) return a.start:GreaterThan(b.start) end)

    for _, edit in ipairs(edits) do
        if edit.kind == "replace" then
            bp.Buf:Replace(edit.start, edit.stop, edit.text)
        else
            bp.Buf:Insert(edit.start, edit.text)
        end
    end
end

function run(bp, args)
    local op, opargs, err = dispatch.parse(args)
    if err then
        micro.InfoBar():Error("ltm: " .. err)
        return
    end

    -- Step 1: read cursor state. All reads happen before any write
    -- so that the inputs aren't perturbed by edits applied later.
    local cursors = bp.Buf:GetCursors()
    local count = #cursors
    local inputs = {}
    local has_sel = {}
    for index = 1, count do
        local cursor = cursors[index]
        if cursor:HasSelection() then
            local sel_start = -cursor.CurSelection[1]
            local sel_stop  = -cursor.CurSelection[2]
            -- Substr returns Go []byte (userdata in Lua). micro/util's
            -- String() converts it to a real Lua string; tostring()
            -- would yield "userdata: 0x...".
            inputs[index] = micro_util.String(bp.Buf:Substr(sel_start, sel_stop))
            has_sel[index] = true
        else
            inputs[index] = ""
            has_sel[index] = false
        end
    end

    -- Step 2: pure transform. outputs[i] == nil means skip cursor i.
    local outputs, rerr = dispatch.run(op, opargs, inputs, count)
    if rerr then
        micro.InfoBar():Error("ltm: " .. rerr)
        return
    end

    -- Step 3: order-independent edit application.
    apply_edits(bp, cursors, has_sel, outputs)
end

function complete(buf)
    -- buf is the command bar buffer. Read its only line and the
    -- cursor's column, then hand off to dispatch.complete.
    local line = buf:Line(0)
    local cursor_x = buf:GetActiveCursor().X
    return dispatch.complete(line, cursor_x)
end

function init()
    config.MakeCommand("ltm", run, complete)
    config.AddRuntimeFile("ltm", config.RTHelp, "help/ltm.md")
end
