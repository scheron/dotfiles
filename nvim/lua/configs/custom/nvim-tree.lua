vim.opt.termguicolors = true
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local HEIGHT_RATIO = 0.8
local WIDTH_RATIO = 0.6

require("nvim-tree").setup {
  view = {
    float = {
      enable = true,
      open_win_config = function()
        local screen_w = vim.opt.columns:get()
        local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
        local window_w = screen_w * WIDTH_RATIO
        local window_h = screen_h * HEIGHT_RATIO
        local window_w_int = math.floor(window_w)
        local window_h_int = math.floor(window_h)
        local center_x = (screen_w - window_w) / 2
        local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
        return {
          border = "rounded",
          relative = "editor",
          row = center_y,
          col = center_x,
          width = window_w_int,
          height = window_h_int,
        }
      end,
    },
    width = function()
      return math.floor(vim.opt.columns:get() * WIDTH_RATIO)
    end,
  },


  filters = { dotfiles = false },
  disable_netrw = true,
  hijack_cursor = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = false,
  },
  renderer = {
    root_folder_label = false,
    -- root_folder_modifier = ":t",
    highlight_git = true,
    indent_markers = { enable = true },
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = false,
        git = true,
      },
      glyphs = {
        default = "󰈚",
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
        },
        git = {
          renamed = "R", -- Renamed
          deleted = "D", -- Deleted
          untracked = "A", -- Added
          unstaged = "M", -- Modified
          staged = "S", -- Staged
          unmerged = "!", -- Merge Conflict
        },
      },
    },
  },
  git = {
    enable = true,
    ignore = true,
    show_on_dirs = true,
    timeout = 500,
  },
}

local tree_api = require "nvim-tree"
local tree_view = require "nvim-tree.view"

vim.api.nvim_create_augroup("NvimTreeResize", {
  clear = true,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = "NvimTreeResize",
  callback = function()
    if tree_view.is_visible() then
      tree_view.close()
      tree_api.open()
    end
  end,
})

-- vim.api.nvim_create_autocmd("VimEnter", {
--   callback = function()
--     view_width_max = vim.o.columns -- Set to full width on the first launch
--     require("nvim-tree.api").tree.open()
--   end,
-- })

-- Open file on create
local api = require("nvim-tree.api")
api.events.subscribe(api.events.Event.FileCreated, function(file)
  vim.cmd("edit " .. file.fname)
end)

vim.cmd.highlight "NvimTreeGitDirty guifg=#e3b341"
vim.cmd.highlight "NvimTreeGitNew guifg=#56d364"
vim.cmd.highlight "NvimTreeGitRenamed guifg=#ADD8E6"
vim.cmd.highlight "NvimTreeGitDeleted guifg=#f85149"
vim.cmd.highlight "NvimTreeGitStaged guifg=#61AFEF"
