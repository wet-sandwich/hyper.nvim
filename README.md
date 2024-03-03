# hyper.nvim

A tool to make requests using **Hyper**text Transfer Protocol (you know, HTTP) within neovim.

## Getting Started

### Required dependencies

- [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim) is required.

### Installation

Use the latest tagged release.

Using [vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'nvim-lua/plenary.nvim'
Plug 'wet-sandwich/hyper.nvim', { 'tag': '0.1.0' }
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'wet-sandwich/hyper.nvim', tag = '0.1.0',
  requires = { {'nvim-lua/plenary.nvim'} }
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'wet-sandwich/hyper.nvim', tag = '0.1.0',
  dependencies = { 'nvim-lua/plenary.nvim' }
}
```

## Usage

Use the command `:Hyper` to open the main window, or add a custom mapping using Lua:

```lua
vim.keymap.set('n', '<leader>hy', require('hyper.view').show, {})
```

Type `q` to close the main window and to close menus without saving changes. Type `<cr>` while in normal mode to save and close a menu or to make a selection.

Type the letters displayed in brackets to open menus or to perform the corresponding action.

#### Body

The body menu appears when a method that supports a body has been selected. The content entered must be valid JSON.

#### Env variables

Enter variables as `key=value` pairs. To use your variables in other places, wrap the key in double braces: `{{key}}`.

#### Query string parameters

Enter parameters as `key=value` pairs.

#### Headers

Enter headers as `Header-Name: value` pairs.
