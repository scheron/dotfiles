local colors = {
	dark_blue_theme = {
		foreground = "#CBE0F0",
		background = "#011423",
		cursor_bg = "#47FF9C",
		cursor_border = "#47FF9C",
		cursor_fg = "#011423",
		selection_bg = "#033259",
		selection_fg = "#CBE0F0",
		ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#A277FF", "#24EAF7", "#24EAF7" },
		brights = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#A277FF", "#24EAF7", "#24EAF7" },
	},
	tokyo_night_theme = {
		foreground = "#C0CAF5",
		background = "#141020",
		cursor_bg = "#C0CAF5",
		cursor_border = "#C0CAF5",
		cursor_fg = "#1A1B26",
		selection_bg = "#33467C",
		selection_fg = "#C0CAF5",
		ansi = { "#1A1B26", "#F7768E", "#9ECE6A", "#E0AF68", "#7AA2F7", "#BB9AF7", "#7DCFFF", "#C0CAF5" },
		brights = { "#2A2B3C", "#F7768E", "#9ECE6A", "#E0AF68", "#7AA2F7", "#BB9AF7", "#7DCFFF", "#FFFFFF" },
	},
}

local color_scheme = {
	"Solarized Dark Higher Contrast",
	"Ef-Night",
	"Gruvbox Dark",
	"Nord",
	"OneDark",
	"Solarized Dark",
	"Solarized Light",
	"Tomorrow Night",
	"Tomorrow Night Bright",
	"Tomorrow Night Eighties",
	"Tomorrow Night Blue",
	"Tomorrow Night Eighties",
}

function setup_theme(config)
	-- config.colors = colors["tokyo_night_theme"]
	config.color_scheme = color_scheme[0]
end

return setup_theme
