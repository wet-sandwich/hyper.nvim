local M = {}

-- history opts
M.history_limit = 25

-- file search depth
M.search_depth = 5

-- view settings
M.viewbox_width_ratio = 0.8
M.viewbox_height_ratio = 0.8

-- highlight groups
M.hl_grp_StatusInfo = "DiagnosticFloatingInfo"
M.hl_grp_StatusOkay = "DiagnosticFloatingOk"
M.hl_grp_StatusWarning = "DiagnosticFloatingWarn"
M.hl_grp_StatusError = "DiagnosticFloatingError"

-- icons
M.icon_enter = "↵"
M.icon_tab = "⇥"
M.icon_selected = "✔"

return M
