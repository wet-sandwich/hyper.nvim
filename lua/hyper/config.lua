local M = {}

M.win = {
  min_width = 80,
  max_width = 140,
  width_ratio = 0.8,
  min_height = 30,
  max_height = 60,
  height_ratio = 0.8,
}

M.layout_config = {
  col_width = 25,
}

M.options = {
  state = vim.fn.stdpath("state") .. "/hyper/state.json",
  history = vim.fn.stdpath("state") .. "/hyper/history.json",
  max_history = 25,
}

return M
