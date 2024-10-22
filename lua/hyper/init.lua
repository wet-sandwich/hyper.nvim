local defaults = require("hyper.defaults")

local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

local M = {}

local function validate_opts(opts)
  assert(type(opts.history_limit) == "number" and opts.history_limit == math.floor(opts.history_limit),
    "hyper.opts.history_limit must be an integer")

  assert(type(opts.search_depth) == "number" and opts.search_depth == math.floor(opts.search_depth),
    "hyper.opts.search_depth must be an integer")

  assert(type(opts.viewbox_width_ratio) == "number" and opts.viewbox_width_ratio <= 1,
    "hyper.opts.viewbox_width_ratio must be a number less than or equal to 1")

  assert(type(opts.viewbox_height_ratio) == "number" and opts.viewbox_height_ratio <= 1,
    "hyper.opts.viewbox_height_ratio must be a number less than or equal to 1")

  assert(vim.fn.hlexists(opts.hl_grp_StatusInfo) ~= 0,
    "hyper.opts.hl_grp_StatusInfo must be a valid highlight group")

  assert(vim.fn.hlexists(opts.hl_grp_StatusOkay) ~= 0,
    "hyper.opts.hl_grp_StatusOkay must be a valid highlight group")

  assert(vim.fn.hlexists(opts.hl_grp_StatusWarning) ~= 0,
    "hyper.opts.hl_grp_StatusWarning must be a valid highlight group")

  assert(vim.fn.hlexists(opts.hl_grp_StatusError) ~= 0,
    "hyper.opts.hl_grp_StatusError must be a valid highlight group")

  assert(type(opts.icon_enter) == "string",
    "hyper.opts.icon_enter must be a string")

  assert(type(opts.icon_tab) == "string",
    "hyper.opts.icon_tab must be a string")

  assert(type(opts.icon_selected) == "string",
    "hyper.opts.icon_selected must be a string")
end

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("keep", opts or {}, defaults)
  validate_opts(M.opts)

  M.state_path = vim.fn.stdpath("state") .. "/hyper/" .. cwd .. "/state.json"
  M.history_path = vim.fn.stdpath("state") .. "/hyper/history.json"

  M.ns = vim.api.nvim_create_namespace("hyper")

  M.mode = {
    main = "main",
    variables = "variables",
    history = "history",
    collections = "collections",
  }
end

return M
