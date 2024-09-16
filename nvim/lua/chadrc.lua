-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}


vim.api.nvim_create_user_command("Theme", function() vim.cmd "Telescope themes" end, {})

M.ui = {
  theme = "tokyonight",
  transparency = true,
  statusline = {
    theme = "vscode_colored",
  },
  nvdash = {
    load_on_startup = true,
    header = {
      "██╗███╗   ██╗███████╗███████╗ ██████╗████████╗███████╗██████╗ ",
      "██║████╗  ██║██╔════╝██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗",
      "██║██╔██╗ ██║█████╗  █████╗  ██║        ██║   █████╗  ██║  ██║",
      "██║██║╚██╗██║██╔══╝  ██╔══╝  ██║        ██║   ██╔══╝  ██║  ██║",
      "██║██║ ╚████║██║     ███████╗╚██████╗   ██║   ███████╗██████╔╝",
      "╚═╝╚═╝  ╚═══╝╚═╝     ╚══════╝ ╚═════╝   ╚═╝   ╚══════╝╚═════╝ ",
      "                                                              ",
      "            ██████╗ ██╗   ██╗         ██╗███████╗             ",
      "            ██╔══██╗╚██╗ ██╔╝         ██║██╔════╝             ",
      "            ██████╔╝ ╚████╔╝          ██║███████╗             ",
      "            ██╔══██╗  ╚██╔╝      ██   ██║╚════██║             ",
      "            ██████╔╝   ██║       ╚█████╔╝███████║             ",
      "            ╚═════╝    ╚═╝        ╚════╝ ╚══════╝             ",
    },

    buttons = {
        { "  Find File", "Spc f f", "Telescope find_files" },
        { "󰈚  Recent Files", "Spc f o", "Telescope oldfiles" },
        { "󰈭  Find Word", "Spc f w", "Telescope live_grep" },
        { "  Themes", "Spc t h", "Telescope themes" },
    }
  },
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
    DiffChange = {
      bg = "#464414",
      fg = "none",
    },
    DiffAdd = {
      bg = "#103057",
      fg = "none",
    },
    DiffRemoved = {
      bg = "#461414",
      fg = "none",
    },
  },

  tabufline = {
    enabled = false,
    lazyload = true,
    override = {},
  },
}

return M
