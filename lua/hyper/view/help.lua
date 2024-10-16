local Float = require("hyper.view.float")

local Help = {}

local help_text = {
  main = {
    "<c-c> close hyper",
    "    R make HTTP request",
    "    M open method menu",
    "    U open URL entry",
    "    P open query parameters editor",
    "    B open request body editor",
    "    H open request headers editor",
    "    X clear all entries",
    "    q close help window",
  },
  history = {
    "<c-c> close window",
    "<c-o> return to main window",
    "    j select next history item",
    "    k select previous history item",
    " <CR> select current request",
    "<del> delete current request",
    "    q close help window",
  },
  variables = {
    "<c-c> close window",
    "<c-o> return to main window",
    "<c-n> preview next env file",
    "<c-p> preview previous env file",
    "<Tab> select current env file",
    "    q close help window",
  },
  collections = {
    "<c-c> close window",
    "<c-o> return to main window",
    "<Tab> switch between collection and request lists",
    "    j select next item",
    "    k select previous item",
    " <CR> select current request",
    "    q close help window",
  },
}

function Help.show(mode)
  local lines = help_text[mode]
  local width = 60
  local vw = vim.o.columns
  local vh = vim.o.lines

  local float = Float.new({
    title = "Help",
    row = math.floor((vh - #lines) / 3),
    col = math.floor((vw - width) / 2),
    width = width,
    height = #lines,
    zindex = 100,
    content = lines,
  })

  float:create_window()
  return float.win
end

return Help
