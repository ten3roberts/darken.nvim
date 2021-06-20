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
  darken = 0.5, -- The factor of which to darken the windows. 0 is completely black, 1 is normal, and 2 is brighter.
  filetypes = { 'NvimTree', 'qf', 'Outline' }, -- Filetypes to darken
}
```

