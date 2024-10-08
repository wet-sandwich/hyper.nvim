local M = {}

local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

M.win = {
  min_width = 80,
  max_width = 140,
  width_ratio = 0.8,
  min_height = 30,
  max_height = 60,
  height_ratio = 0.8,
}

M.viewbox = {
  width = 0.8,
  height = 0.8,
}

M.layout_config = {
  col_width = 25,
}

M.options = {
  state = vim.fn.stdpath("state") .. "/hyper/" .. cwd .. "/state.json",
  history = vim.fn.stdpath("state") .. "/hyper/history.json",
  max_history = 25,
}

M.ns = vim.api.nvim_create_namespace("hyper")

M.hl_grp = {
  HttpStatusOk = "DiagnosticFloatingOk",
  HttpStatusInfo = "DiagnosticFloatingInfo",
  HttpStatusWarning = "DiagnosticFloatingWarn",
  HttpStatusError = "DiagnosticFloatingError",
}

return M
