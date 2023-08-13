local w = vim.w
local o = vim.o
local api = vim.api
local cmd = vim.cmd
local fn = vim.fn

local M = {}

local defaults = {
	amount = 0.7,
	group = "Normal",
	filetypes = { "NvimTree", "qf", "Outline", "help", "dap.*", "aerial" },
	buftypes = { "terminal" },
}

M.config = defaults

-- Convert hex code to r,g,b
local function to_rgb(color)
	return tonumber(color:sub(2, 3), 16), tonumber(color:sub(4, 5), 16), tonumber(color:sub(6), 16)
end

local function darken_color(color, amount)
	if vim.o.background == "light" then
		amount = 2.0 - amount
	end
	local r, g, b = to_rgb(color)
	-- If any of the colors are missing return 'NONE' i.e. no highlight
	if not r or not g or not b then
		return "NONE"
	end

	-- Darken by amount factor
	r = math.min(math.floor(r * amount), 255)
	g = math.min(math.floor(g * amount), 255)
	b = math.min(math.floor(b * amount), 255)

	-- Convert back to hex
	return string.format("#%02x%02x%02x", r, g, b)
end

function M.setup(config)
	config = vim.tbl_extend("force", defaults, config or {})

	M.config = config

	local group = api.nvim_create_augroup("Darken", { clear = true })
	local function au(event, callback)
		api.nvim_create_autocmd(event, { callback = callback, group = group })
	end

	au({ "Filetype", "BufWinEnter", "WinEnter", "WinNew", "TermEnter", "TermOpen" }, function(o)
		if api.nvim_win_get_buf(api.nvim_get_current_win()) ~= o.buf then
			-- vim.notify(string.format("Autocommand %q did not match window", o.event))
		end

		local current_win = api.nvim_get_current_win()
		for _, win in ipairs(vim.fn.win_findbuf(o.buf)) do
			M.darken(win)
		end
	end)
	au({ "ColorScheme" }, M.configure_hl)

	M.configure_hl()
end

function M.get_bg_color()
	local amount = M.config.amount
	return darken_color(fn.synIDattr(fn.hlID(M.config.group or "Normal"), "bg"), amount)
end

local ns_id = api.nvim_create_namespace("Darken")

-- Create highlight groups
function M.configure_hl()
	local amount = M.config.amount
	local dark_bg = darken_color(fn.synIDattr(fn.hlID(M.config.group or "Normal"), "bg"), amount)
	local statusline_bg = darken_color(fn.synIDattr(fn.hlID("StatusLine"), "bg"), amount)
	local statusline_nc_bg = darken_color(fn.synIDattr(fn.hlID("StatusLine"), "bg"), math.pow(amount, 1.0 / 1.2))
	local cursorline_bg = darken_color(fn.synIDattr(fn.hlID("CursorLine"), "bg"), amount)

	api.nvim_set_hl(0, "Darkened", { bg = dark_bg })
	api.nvim_set_hl(0, "DarkenedStatusline", { bg = statusline_bg })
	api.nvim_set_hl(0, "DarkenedStatuslineNC", { bg = statusline_nc_bg })
	api.nvim_set_hl(0, "DarkenedFull", { bg = dark_bg, fg = dark_bg })

	api.nvim_set_hl(ns_id, "Normal", { link = "Darkened" })
	api.nvim_set_hl(ns_id, "AerialNormal", { link = "Darkened" })
	api.nvim_set_hl(ns_id, "EndOfBuffer", { link = "DarkenedFull" })
	api.nvim_set_hl(ns_id, "StatusLine", { link = "DarkenedStatusline" })
	api.nvim_set_hl(ns_id, "StatusLineNC", { link = "DarkenedStatusLineNC" })
	api.nvim_set_hl(ns_id, "SignColumn", { link = "Darkened" })
	api.nvim_set_hl(ns_id, "CursorLine", { link = "Darkened" })
end

local cache_ft = {}
local cache_bt = {}

local function matched(cache, list, val)
	local c = cache[val]
	if c ~= nil then
		return c
	end

	for _, pat in ipairs(list) do
		if string.match(val, pat) ~= nil then
			cache[val] = true
			return true
		end
	end

	cache[val] = false
	return false
end

function M.darken(winid)
	local bufnr = api.nvim_win_get_buf(winid)
	local ft = api.nvim_buf_get_option(bufnr, "filetype")
	local bt = api.nvim_buf_get_option(bufnr, "buftype")

	local ft = matched(cache_ft, M.config.filetypes, ft)
	local bt = matched(cache_bt, M.config.buftypes, bt)

	if ft or bt then
		M.set_hl(winid)
	elseif vim.w[winid].darkened == 1 then
		M.remove_hl(winid)
	end
end

function M.remove_hl(winid)
	api.nvim_win_set_hl_ns(winid, 0)
	api.nvim_win_set_var(winid, "darkened", nil)

	local bufnr = api.nvim_win_get_buf(winid)
	local bufname = api.nvim_buf_get_name(bufnr)
	local ft = vim.bo[bufnr].filetype
	local bt = vim.bo[bufnr].buftype

	-- vim.notify(string.format("Removing highlight of %s %s:%s", bufname, ft, bt))
end

-- Forcibly darkens the current buffer
function M.set_hl(winid)
	local bufnr = api.nvim_win_get_buf(winid)
	local bufname = api.nvim_buf_get_name(bufnr)
	local ft = vim.bo[bufnr].filetype
	local bt = vim.bo[bufnr].buftype

	-- vim.notify(string.format("Darkening %s %s:%s", bufname, ft, bt))

	api.nvim_win_set_hl_ns(winid, ns_id)
	-- Keep track if window was highlighted by this plugin to not conflict with
	-- other plugins winhighlight, like Telescope does.
	api.nvim_win_set_var(winid, "darkened", 1)
end

return M
