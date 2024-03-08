local Util = require("hyper.util")
local Config = require("hyper.config")

local M = {}

setmetatable(M, {
  __call = function(_, ...)
    return M.new(...)
  end,
})

function M.new(...)
  local self = setmetatable({}, { __index = M })
  return self:init()
end

function M:init(opts)
  local win = Config.win
  local w = Util.get_dimension(vim.o.columns, win.min_width, win.max_width, win.width_ratio)
  local h = Util.get_dimension(vim.o.lines, win.min_height, win.max_height, win.height_ratio)

  self.opts = vim.deepcopy(opts)

  self.win_opts = {
    style = "minimal",
    relative = "editor",
    width = w.dim,
    height = h.dim,
    row = h.pos - 2,
    col = w.pos,
    border = "rounded",
    title = self.opts.title,
    title_pos = self.opts.title_pos,
    noautocmd = self.opts.noautocmd,
  }

  self:mount()
  self:on_key("q", self.close, "close window")
  return self
end

function M:mount()
  if self:buf_valid() then
    self.buf = self.buf
  else
    self.buf = vim.api.nvim_create_buf(false, true)
  end

  self.win = vim.api.nvim_open_win(self.buf, true, self.win_opts)
end

function M:on_key(key, fn, desc)
  vim.keymap.set("n", key, function()
    fn(self)
  end, {
    nowait = true,
    buffer = self.buf,
    desc = desc,
  })
end

function M:close()
  local buf = self.buf
  local win = self.win

  self.win = nil
  vim.schedule(function()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
end

function M:buf_valid()
  return self.buf and vim.api.nvim_buf_is_valid(self.buf)
end

function M:focus()
  vim.api.nvim_set_current_win(self.win)

  if vim.v.vim_did_enter ~= 1 then
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        if self.win and vim.api.nvim_win_is_valid(self.win) then
          pcall(vim.api.nvim_set_current_win, self.win)
        end
        return true
      end,
    })
  end
end

return M
