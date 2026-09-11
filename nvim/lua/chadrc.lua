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

-- NvChad's statusline reports the first client by id, which on a .tsx or .vue
-- buffer is whichever helper server started fastest rather than the one doing
-- the work. List every attached client, helpers last.
local lsp_helpers = { emmet_language_server = true, tailwindcss = true }

local function lsp_status()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
  local names, helpers = {}, {}

  for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    table.insert(lsp_helpers[client.name] and helpers or names, client.name)
  end

  vim.list_extend(names, helpers)

  if #names == 0 then
    return ""
  end

  local label = (vim.o.columns > 100 and "   LSP ~ " .. table.concat(names, ", ") .. " ") or "   LSP "
  return "%#St_Lsp#" .. label
end

M.ui = {
  statusline = {
    theme = "vscode_colored",
    modules = {
      lsp = lsp_status,
    },
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
