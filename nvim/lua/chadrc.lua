-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

vim.api.nvim_create_user_command("Theme", function()
  vim.cmd "Telescope themes"
end, {})

M.base46 = {
  theme = "tokyonight",
  transparency = true,
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
}

M.ui = {
  statusline = {
    theme = "vscode_colored",
  },

  tabufline = {
    enabled = false,
    lazyload = true,
  },
}

M.nvdash = {
  load_on_startup = true,

  header = {
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⠏⠀⠙⢦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⠃⠀⠀⢱⡈⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⢠⠏⠀⠀⠀⠀⣧⠘⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⡀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⣾⠀⠀⠀⠀⣤⡟⠀⣷⣤⣀⣀⠀⠀⠀⣠⡴⠞⣋⡩⠉⣹⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⢀⣟⠀⠀⢀⣼⠛⠁⠀⠉⠀⠀⠉⠛⢶⡋⠁⣠⠞⠁⠀⢀⡏⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⢸⡀⠀⠲⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⢸⡷⠀⠀⢀⡞⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⣰⠏⠧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣯⢀⣰⠏⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⢰⠇⠀⠀⠲⢿⣿⣿⣿⣶⣶⣤⡀⠀⠀⠀⠀⠀⠀⢸⡽⠁⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⡿⠀⠀⢀⠀⠐⣿⣿⣿⣿⣿⣿⣿⠿⣷⣾⣿⣿⣷⣾⣤⡀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⢰⡇⠀⠀⠨⡆⠀⠻⣿⣿⣿⣿⣿⠏⠀⢻⣿⣿⣿⣿⣿⡏⠁⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⡾⠀⠀⠀⠀⠈⠀⠀⠀⠉⠉⠉⠁⠀⢰⣿⣿⣿⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⣸⠃⠀⠀⠀⠀⠀⠀⠘⠲⢤⣀⠘⠦⣤⣬⣟⠋⣀⡾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢲⡶⠖⠋⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⡏⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠛⠶⣧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠐⣇⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢙⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠓⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⢻⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣄⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠈⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⡆⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⣻⠀⠀⢠⣀⡦⠴⠤⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⢸⠀⠀⣰⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⢸⠀⠀⣟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⢸⠀⠀⢻⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡟⠀⠀⠀⣠⡆⠀⠀",
    "⠀⠀⠀⣀⡾⠀⠀⣸⢳⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠦⣤⣾⣁⣤⠴⠛⢁⡇⠀⠀",
    "⠀⠀⢸⡵⠀⠀⢠⢟⠍⠉⠓⠄⠀⠀⠀⠀⠀⠀⠀⠀⣆⠀⠀⠀⠀⠀⠀⠀⠀⢠⡾⠀⠀⠀",
    "⠀⠀⠈⠙⠛⠛⠉⠻⠶⠶⠤⠤⣤⣤⣤⣤⠗⠒⠒⠒⠛⠳⢤⣦⣄⣀⣰⣶⠖⠋⠁⠀⠀⠀",
  },

  buttons = {},
}

if vim.tbl_isempty(M.nvdash.buttons) then
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "nvdash",
    callback = function(args)
      for _, key in ipairs { "j", "k", "<up>", "<down>", "<cr>" } do
        pcall(vim.keymap.del, "n", key, { buffer = args.buf })
      end
    end,
  })
end

return M
