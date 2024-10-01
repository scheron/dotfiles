local wezterm = require("wezterm")
local config = wezterm.config_builder()

require("setup_theme")(config)

config.window_background_opacity = 0.7
config.macos_window_background_blur = 50
config.font = wezterm.font("Fragment Mono")
config.font_size = 19

config.window_decorations = "RESIZE"
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.enable_tab_bar = false

return config
