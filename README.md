# darken.nvim

A Neovim plugin for darkening windows of certain filetypes.

## Motivation

Having many windows open in vim can be confusing at times, especially when they
blend together. By darkening windows of a certain filetype like tree explorers
or quickfix lists, the important splits containing the actively worked on code
stands out and becomes much clearer.

## Usage

Configuration is done by passing a table to the setup function
```lua
require'darken'.setup{
  -- Amount to darken by. Can be above 1.0, in which case it will brighten, or
  1.0 in which nothing will be changed.
  amount = 0.7,
  group = 'Normal' -- Highlight group to take the background from.
  -- Filetypes to darken
  filetypes = { 'NvimTree', 'qf', 'Outline' }
}
```

