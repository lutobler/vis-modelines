--
-- vis-modelines
--
-- Vim's modelines are very useful for setting per-file settings in Vim.
-- For example, the filetype can't always be reliably inferred from the
-- filename, i.e. for templates with generic file extensions or script files
-- that omit the file extension altogether.
--
-- This Vis plugin tries to read standard Vim modelines and set the following
-- (Vis) settings:
--
-- autoindent, expandtab, numbers, tabwidth, syntax.
--
-- Vim (by default) looks for modelines in the first 5 and last 5 lines of the
-- file. This will emulate this behaviour, but omit the setting to change this
-- threshold, as no sane person would change it (it would break everybody
-- else's Vim).
--
-- This parser assumes you will only use *one* modeline per file, to avoid
-- having to resolve conflicts. It will use the first modeline it finds from
-- the top.
--

local lpeg = require("lpeg")
local P, C, Ct, R, S = lpeg.P, lpeg.C, lpeg.Ct, lpeg.R, lpeg.S

local M = {}

-- vim has two styles for modelines:
--
-- 'set' style, can be delimeted with a : at the end. Delimter is whitespace.
-- E.g.: vim: set ft=lua sw=2 ts=2 autoindent:
--
-- Colon style, modeline continues to the end of the line. Delimeter is
-- whitespace or ':'.
-- E.g.: vim: noai:ts=4:sw=4 ft=lua

local digit = R("09")
local num = digit * digit * digit           -- 3-digit version number
local ver = (S("><=") * num) + num + P("")
local vim = P(" vim") * ver * ":"           -- only 'vim', 'Vim' can have
            + P(" Vim") * ver * ":"         -- version numbers
            + P(" vi:")
            + P(" ex:")

local whitespace = S('\t ')^1               -- atleast one whitespace character
local optwhitespace = whitespace + P("")    -- 0 or more whitespace characters
local prefix = (1-vim)^0 * vim

-- The options can basically be arbitrarily insane. I have no idea what
-- characters can be used.
local optchars = R("az", "AZ") + R("09") + S("_\"\'")
local option = Ct(C(optchars^1) * "=" * C(optchars^1)) + C(optchars^1)

local set = P("set") + P("se")
local setstyle = optwhitespace * set * (whitespace * option)^0 * P(":")^-1
local separator = (optwhitespace * P(":") * optwhitespace) + whitespace
local colonstyle = optwhitespace * option * (separator * option)^0

-- matches & captures options
local modeline = Ct(prefix * (setstyle + colonstyle))

-- detects modelines
local modeline_detect = prefix * whitespace

-- Simple Vim settings like 'autoindent' without options are mapped directly to
-- a command for Vis. If the settings is a variable (like 'ft=lua'), a mapping
-- function is used to generate the Vis command.

local sw_set = false

local function sw_f(value)
    sw_set = true
    return "set tw "..value
end

local function ts_f(value)
    if not sw_set then
        return "set tw "..value
    else
        return nil
    end
end

local command_mapping = {
    autoindent      = "set ai on",
    noautoindent    = "set ai off",
    ai              = "set ai on",
    noai            = "set ai off",
    expandtab       = "set et on",
    noexpandtab     = "set et off",
    et              = "set et on",
    noet            = "set et off",
    number          = "set nu on",
    nonumber        = "set nu off",
    nu              = "set nu on",
    nonu            = "set nu off",
    ft              = function(value) return "set syntax "..value end,
    filetype        = function(value) return "set syntax "..value end,

    -- Vis only knows the 'tabwidth' setting instead of 'sw' and 'ts' settings.
    -- We prefer the 'sw' setting for 'tabwidth', because it is what the
    -- modeline wants to be inserted. How it is displayed is somewhat less
    -- important.
    sw              = sw_f,
    shiftwidth      = sw_f,
    ts              = ts_f,
    tabstop         = ts_f
}

function M.parse_modeline(line)
    local commands = {}
    local opts = modeline:match(line)
    if not opts then return nil end

    for _,o in pairs(opts) do
        if type(o) == "string" then     -- simple options are stored as strings
            local c = command_mapping[o]
            if c then
                table.insert(commands, c)
            end
        elseif type(o) == "table" then  -- variables are stored as a table
            local map_f = command_mapping[o[1]]
            if map_f then
                local c = map_f(o[2])
                if c then table.insert(commands, c) end
            end
        end
    end
    return commands
end

function M.find_modeline(lines)
    if not lines then return nil end
    if #lines < 10 then
        for i=1,#lines do
            local l = lines[i]
            if modeline_detect:match(l) then
                return l
            end
        end
    else
        for i=1,5 do
            local l = lines[i]
            if modeline_detect:match(l) then
                return l
            end
        end
        for i=0,4 do
            local l = lines[#lines - i]
            if modeline_detect:match(l) then
                return l
            end
        end
    end
    return nil
end

function M.event_read_modeline(win)
    local file = win.file
    if not file then return end
    local ml = M.find_modeline(file.lines)
    if not ml then return end
    local commands = M.parse_modeline(ml)
    for _,i in pairs(commands) do
        vis:command(i)
    end
end

return M
