local wezterm = require("wezterm")
local config = wezterm.config_builder()

math.randomseed(os.time())

local themes = require("themes")
local random_theme = themes[math.random(#themes)]
config.colors = random_theme

-- local schemes = require("color_schemes")
-- local random_scheme = schemes[math.random(#schemes)]
-- config.color_scheme = random_scheme

config.window_background_opacity = 0.7
config.macos_window_background_blur = 50
config.font = wezterm.font("SauceCodePro Nerd Font")
config.font_size = 19

config.window_decorations = "RESIZE"
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.enable_tab_bar = false

return config
