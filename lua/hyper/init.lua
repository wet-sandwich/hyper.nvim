local defaults = require("hyper.defaults")

local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

local M = {}

local function validate_opts(opts)
  assert(type(opts.history_limit) == "number" and opts.history_limit == math.floor(opts.history_limit),
    "hyper.opts.history_limit must be an integer")

  -- WIP
  -- assert(type(opts.viewbox_width_ratio) == "number" and opts.viewbox_width_ratio <= 1,
  --   "hyper.opts.viewbox_width_ratio must be a number less than or equal to 1")
  --
  -- assert(type(opts.viewbox_height_ratio) == "number" and opts.viewbox_height_ratio <= 1,
  --   "hyper.opts.viewbox_height_ratio must be a number less than or equal to 1")
end

function M.setup(opts)
  opts = opts or {}
  M.opts = setmetatable(opts, { __index = defaults })
  validate_opts(M.opts)

  M.layout_col_width = 25

  M.state_path = vim.fn.stdpath("state") .. "/hyper/" .. cwd .. "/state.json"
  M.history_path = vim.fn.stdpath("state") .. "/hyper/history.json"

  M.ns = vim.api.nvim_create_namespace("hyper")
end

return M
