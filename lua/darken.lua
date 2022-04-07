local w = vim.w
local o = vim.o
local cmd = vim.cmd
local fn = vim.fn

local defaults = {
  amount = 0.7,
  group = 'Normal',
  filetypes = { 'NvimTree', 'qf', 'Outline' }
}

-- Convert hex code to r,g,b
local function to_rgb(color)
  return tonumber(color:sub(2, 3), 16), tonumber(color:sub(4, 5), 16), tonumber(color:sub(6), 16)
end

local function darken_color(color, amount)
  local r, g, b = to_rgb(color)
  -- If any of the colors are missing return 'NONE' i.e. no highlight
  if not r or not g or not b then
    return 'NONE'
  end

  -- Darken by amount factor
  r = math.min(math.floor(r * amount), 255)
  g = math.min(math.floor(g * amount), 255)
  b = math.min(math.floor(b * amount), 255)

  -- Convert back to hex
  return string.format('#%02x%02x%02x', r, g, b)
end

local M = {}

function M.setup(config)
  config = vim.tbl_extend('force', defaults, config or {})

  -- Convert the list into a set
  local filetypes = {}
  for _,v in pairs(config.filetypes) do
    filetypes[v] = true
  end

  config.filetypes = filetypes

  M.config = config

  cmd [[
  augroup Darken
  autocmd!
  autocmd Filetype,BufWinEnter,WinEnter,WinNew,TermEnter,TermOpen * lua require'darken'.darken()
  autocmd ColorScheme * lua require'darken'.set_highlights()
  augroup END
  ]]

  M.set_highlights()
end

-- Create highlight groups
function M.set_highlights()
  local amount = M.config.amount
  local normal_bg = darken_color(fn.synIDattr(fn.hlID(M.config.group or 'Normal'), 'bg'), amount)
  local cursorline_bg = darken_color(fn.synIDattr(fn.hlID('CursorLine'), 'bg'), amount)

  cmd('hi! DarkenedBg guibg=' .. normal_bg)
  cmd('hi! DarkenedFull guibg=' .. normal_bg .. ' guifg=' .. normal_bg)
  cmd('hi! DarkenedStatusline gui=NONE guibg=' .. normal_bg)
  cmd('hi! DarkenedCursorLine gui=NONE guibg=' .. cursorline_bg)
  -- setting cterm to italic is a hack
  -- to prevent the statusline caret issue
  cmd('hi! DarkenedStatuslineNC cterm=italic gui=NONE guibg=' .. normal_bg)
end

local highlights = table.concat({
  'Normal:DarkenedBg',
  'EndOfBuffer:DarkenedBg',
  'EndOfBuffer:DarkenedFull',
  'StatusLine:DarkenedStatusline',
  'StatusLineNC:DarkenedStatuslineNC',
  'SignColumn:DarkenedBg',
  'CursorLine:DarkenedCursorLine',
}, ',')

function M.darken()
  local ft = o.ft or "none"

  if M.config.filetypes[ft] == nil and w.darkened ~= ft then
    -- Remove hightlight
    if w.darkened then
      cmd 'setlocal winhighlight='
      w.darkened = nil
    end
    return
  end

  M.force_darken("soft")
end

-- Forcibly darkens the current buffer
function M.force_darken(val)
  cmd('setlocal winhighlight=' .. highlights)

  -- Keep track if window was highlighted by this plugin to not conflict with
  -- other plugins winhighlight, like Telescope does.
  w.darkened = o.ft or "none"
end

return M
