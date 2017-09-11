## vis-modelines

Vim's modelines are very useful for setting per-file settings in Vim.
For example, the filetype can't always be reliably inferred from the filename, i.e. for templates with generic file extensions or script files that omit the file extension altogether.

This Vis plugin tries to read standard Vim modelines and set the following (Vis) settings:

`autoindent`, `expandtab`, `numbers`, `tabwidth`, `syntax`.

Vim (by default) looks for modelines in the first 5 and last 5 lines of the file. This will emulate this behaviour, but omit the setting to change this threshold, as no sane person would change it (it would break everybody else's Vim).

This parser assumes you will only use *one* modeline per file, to avoid having to resolve conflicts. It will use the first modeline it finds from the top.

### Usage
Add this to your `visrc.lua`:
```
local modeline = require("vis-modelines")
vis.events.subscribe(vis.events.WIN_OPEN, modeline.event_read_modeline)
```

The reason why `vis-modelines` exports the event function as a module and doesn't set it directly, is that the order the events are called is the order the events are registered. `event_read_modeline` needs to be called *after* the typical intialization, so settings from the modeline are not overwritten by those defaults.

