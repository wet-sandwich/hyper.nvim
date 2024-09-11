local Config = require("hyper.config")

local Float = {}
Float.__index = Float

function Float.new(opts)
  opts.buf = 0
  opts.win = 0
  opts.keymaps = {}
  opts.autocmds = {}
  setmetatable(opts, Float)
  return opts
end

function Float:create_window()
  local bufnr = vim.api.nvim_create_buf(false, true)
  local winid = vim.api.nvim_open_win(bufnr, self.enter or false, {
    style = "minimal",
    relative = "editor",
    width = self.width,
    height = self.height,
    row = self.row,
    col = self.col,
    border = "rounded",
    title = self.title,
  })

  self.buf = bufnr
  self.win = winid

  if self.filetype ~= nil then
    vim.bo.ft = self.filetype
  end

  self:_disable_jump()
  self:_set_keymaps()
  self:_set_autocmds()
  self:render()
end

function Float:render()
  vim.api.nvim_win_set_hl_ns(self.win, Config.ns)
  vim.api.nvim_buf_set_option(self.buf, "modifiable", true)

  if type(self.content) == "function" then
    local text = self.content()
    text:render(self.buf)
  else
    vim.api.nvim_buf_set_lines(self.buf, -2, -1, false, {})
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, self.content)
  end

  vim.api.nvim_buf_set_option(self.buf, "modifiable", self.editable or false)
end

function Float:add_keymap(map)
  table.insert(self.keymaps, map)
end

function Float:_set_keymaps()
  for _, map in ipairs(self.keymaps) do
    local mode, lhs, rhs = unpack(map)
    self:set_keymap(mode, lhs, rhs)
  end
end

function Float:set_keymap(modes, lhs, rhs)
  vim.keymap.set(modes, lhs, rhs, {
    nowait = true,
    buffer = self.buf
  })
end

function Float:add_autocmd(event, opts)
  table.insert(self.autocmds, {
    event = event,
    opts = opts,
  })
end

function Float:_set_autocmds()
  for _, cmd in ipairs(self.autocmds) do
    local opts = vim.tbl_extend("force", cmd.opts, { buffer = self.buf })
    vim.api.nvim_create_autocmd(cmd.event, opts)
  end
end

function Float:_disable_jump()
  self:set_keymap("n", "<c-o>", "")
  self:set_keymap("n", "<c-i>", "")
end

return Float
