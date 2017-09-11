local mparser = require("vis-modelines-parser")

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
    local file = win.file
    if not file then return end
    local ml = mparser.find_modeline(file.lines)
    if not ml then return end
    local commands = mparser.parse_modeline(ml)
    for _,i in pairs(commands) do
        local c = "set " .. i
        vis:command(c)
    end
end)
