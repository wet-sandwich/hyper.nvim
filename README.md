# hyper.nvim

A tool to make requests using **Hyper**text Transfer Protocol (you know, HTTP) within neovim.

## Usage

Use the command `:Hyper` to open the main window.

Type `q` to close the main window and to close menus without saving changes. Type `<cr>` while in normal mode to save and close a menu or to make a selection.

Type the letters displayed in brackets to open menus or to perform the corresponding action.

### Body

The body menu appears when a method that supports a body has been selected. The content entered must be valid JSON.

### Env Variables

Enter variables as `key=value` pairs. To use your variables in other places, wrap the key in double braces: `{{key}}`.

### Query String Parameters

Enter parameters as `key=value` pairs.

### Headers

Enter headers as `Header-Name: value` pairs.
