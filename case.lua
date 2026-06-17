-- case: upper/lower letter-case transforms over a selection. See
-- util.lua header for the dual-load design.

local M = {}

function M.upper(sel)
    if sel == "" then
        return nil
    end
    return sel:upper()
end

function M.lower(sel)
    if sel == "" then
        return nil
    end
    return sel:lower()
end

case = M
return M
