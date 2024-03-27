-- local CodyPrompt = require "sg.components.cody_prompt"
-- local CodyHistory = require "sg.components.cody_history"
-- local Message = require "sg.cody.message"
-- local CodySpeaker = require("sg.types").CodySpeaker
-- local State = require "sg.cody.state"

local State = require("hyper.state")

---@class CodyBaseLayoutOpts
---@field id string: ID sent from cody-agent
---@field name? string
---@field reset? boolean
---@field code_only? boolean
---@field state? cody.State
---@field prompt? CodyPromptOpts
---@field history? CodyHistoryOpts

---@class CodyBaseLayout
---@field opts CodyBaseLayoutOpts
---@field state cody.State
---@field history CodyHistory
---@field prompt CodyPrompt?
---@field code_only boolean
---@field _active CodyBaseLayout?
local View = {}
View.__index = View

--- Create a new base layout object
---@param opts CodyBaseLayoutOpts
---@return CodyBaseLayout
function View.init(opts)
  -- local state = opts.state
  -- if opts.reset then
  --   state = State.init { id = opts.id, name = opts.name, code_only = opts.code_only }
  -- else
  --   if not state then
  --     -- state = State.last() or State.init { name = opts.name }
  --     state = State.init { id = opts.id, name = opts.name, code_only = opts.code_only }
  --   end
  -- end

  local state = State
  state.init()

  return setmetatable({
    opts = opts,
    state = state,
  }, View)
end

-- TODO: This doesn't really let us have multiple "active" windows...
-- I'll have to think about how to register this kind of idea.
--
-- Possibly an autocmd when entering a cody window that sets it to the
-- most recently active window?
function View:get_active()
  return View._active
end

function View:set_active(obj)
  View._active = obj
end

function View:is_visible()
  return self.history and self.history.win and vim.api.nvim_win_is_valid(self.history.win)
end

function View:toggle()
  local active = self:get_active()
  if not active then
    ---@diagnostic disable-next-line: missing-fields
    active = self.init {}
  end

  if not active:is_visible() then
    return active:show()
  else
    return active:hide()
  end
end

function View:create()
  local active = self:get_active()
  if active then
    active:delete()
    self:set_active(nil)
  end

  self.history = CodyHistory.init(self.opts.history)
  if self.opts.prompt then
    -- Override prompt options
    -- TODO: Do the other options as well
    local prompt_opts = assert(vim.deepcopy(self.opts.prompt))
    prompt_opts.on_submit = function(bufnr, text)
      if self.opts.prompt.on_submit then
        self.opts.prompt.on_submit(bufnr, text)
      end

      self:on_submit(bufnr, text)
    end

    prompt_opts.on_close = function()
      if self.opts.prompt.on_close then
        self.opts.prompt.on_close()
      end

      self:delete()
    end

    self.prompt = CodyPrompt.init(prompt_opts)
  end

  self.created = true

  -- Reset the chat
  if self.opts.reset then
    require("sg.cody.rpc").transcript.reset()
  end
end

--- Show the layout
---@param self CodyBaseLayout
function View:show()
  if not self.created then
    self:create()
  end

  self:set_active(self)

  self.history:show()
  if self.prompt then
    self.prompt:show()
    vim.api.nvim_set_current_win(self.prompt.win)

    vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
      buffer = self.prompt.bufnr,
      once = true,
      callback = function()
        self.prompt:on_close()
      end,
    })
  end

  self:set_keymaps()
  self:render()
end

--- Render the layout with the current state
function View:render()
  if self.created then
    self.state:render(self.history.bufnr, self.history.win)
  end
end

function View:hide()
  self.history:hide()
  if self.prompt then
    self.prompt:hide()
  end
end

function View:delete()
  self.history:delete()
  if self.prompt then
    self.prompt:delete()
  end

  self.created = false
end

--- Callback for running on submit
function View:on_submit(_, text)
  self.state:submit(Message.init(CodySpeaker.human, text))
end

function View:set_keymaps()
  if self.prompt then
    vim.api.nvim_buf_create_user_command(self.prompt.bufnr, "CodySubmit", function()
      self.prompt:on_submit()
    end, {})
  end
end

return View
