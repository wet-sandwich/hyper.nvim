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
  HttpStatusOk = "HyperOkStatus",
  HttpStatusInfo = "HyperInfoStatus",
  HttpStatusWarning = "HyperWarningStatus",
  HttpStatusError = "HyperErrorStatus",
}

vim.api.nvim_set_hl(M.ns, M.hl_grp.HttpStatusOk, { fg = "black", bg = "green" })
vim.api.nvim_set_hl(M.ns, M.hl_grp.HttpStatusInfo, { fg = "black", bg = "blue" })
vim.api.nvim_set_hl(M.ns, M.hl_grp.HttpStatusWarning, { fg = "black", bg = "yellow" })
vim.api.nvim_set_hl(M.ns, M.hl_grp.HttpStatusError, { fg = "black", bg = "red" })

return M
