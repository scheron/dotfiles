require("telescope").setup {
  defaults = {
    sorting_strategy = "ascending",
    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "truncate" },
    file_ignore_patterns = { "node_modules", ".git" },
    mappings = {
      i = {
        ["<CR>"] = function(prompt_bufnr)
          require("telescope.actions").close(prompt_bufnr)
          require("telescope.actions").select_default(prompt_bufnr)
        end,
      },
    },
  },
  pickers = {
    find_files = { theme = "dropdown" },
    buffers = { theme = "dropdown" },
    live_grep = { theme = "dropdown" },
    grep_string = { theme = "dropdown" },
    git_files = { theme = "dropdown" },
    todos = { theme = "dropdown" },
    lsp_definitions = { -- Настройка для `gd` (Go to Definition)
      theme = "dropdown",
      attach_mappings = function(_, map)
        map("i", "<CR>", function(prompt_bufnr)
          require("telescope.actions").close(prompt_bufnr)
          require("telescope.actions").select_default(prompt_bufnr)
        end)
        return true
      end,
    },
  },
}

vim.keymap.set("n", "gd", function()
  require("telescope.builtin").lsp_definitions()
end, { desc = "Go to Definition (Telescope, auto-close)" })
