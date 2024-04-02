# hyper.nvim

A tool to make requests using **Hyper**text Transfer Protocol (you know, HTTP) within neovim.

![hyper.request_response](https://imgur.com/HUKDiXX.png)

## Getting Started

### Required dependencies

- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) is required.

### Installation

Use the latest tagged release.

Using [vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'nvim-lua/plenary.nvim'
Plug 'wet-sandwich/hyper.nvim', { 'tag': '0.1.3' }
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'wet-sandwich/hyper.nvim', tag = '0.1.3',
  requires = { {'nvim-lua/plenary.nvim'} }
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'wet-sandwich/hyper.nvim', tag = '0.1.3',
  dependencies = { 'nvim-lua/plenary.nvim' }
}
```

## Usage

Use the command `:Hyper` to open the main window, or add a custom mapping using Lua:

```lua
vim.keymap.set('n', '<leader>hy', require('hyper.view').show, {})
```

Type `<c-c>` to close the main window and to close menus without saving changes. Type `<cr>` while in normal mode to save and close a menu or to make a selection.

Type the letters displayed in brackets to open menus or to perform the corresponding action.

After navigating to another screen, type `<c-o>` to return to the main
request/response screen.

#### Body

The body menu appears when a method that supports a body has been selected. The content entered must be valid JSON.

![hyper.request_body](https://imgur.com/w200fdx.png)

#### Env variables

Hyper will search the current working directory (and up to four levels deep) for any .env files (including those with prefixes or suffixes), and will try to auto-select one for you. If multiple files are found you can select which one to use, and you can edit the selected file from within Hyper. Use `<c-n>` and `<c-p>` to move to different files and preview their contents. Type `<Tab>` to select a file to be used to fill in variables when making a request. The current selected file is marked with a check mark.

Enter variables as `key=value` pairs. To use your variables in other places, wrap the key in double braces: `{{key}}`.

![hyper.env_variables](https://imgur.com/F30OwS9.png)

#### Query string parameters

Enter parameters as `key=value` pairs.

#### Headers

Enter headers as `Header-Name: value` pairs.

![hyper.request_headers](https://imgur.com/xrqvDuO.png)

#### Request History

Hyper will track your 25 previous unique requests. Use `<c-n>` and `<c-p>` to
cycle through the list and preview the full request. Type `<cr>` to select a
previous request and copy its contents to the active request.

Repeating a previous request moves it to the top of the list with an updated
timestamp instead of creating a new entry.

![hyper.request_history](https://imgur.com/fpXRibI.png)
