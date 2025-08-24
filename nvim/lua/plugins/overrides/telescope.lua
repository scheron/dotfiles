require("telescope").setup {
  defaults = {
    sorting_strategy = "ascending",
    prompt_prefix = " ",
    selection_caret = " ",
    path_display = { "truncate" },
    file_ignore_patterns = { "node_modules", ".git" },
  },
  pickers = {
    find_files = { theme = "dropdown" },
    buffers = { theme = "dropdown" },
    live_grep = { theme = "dropdown" },
    grep_string = { theme = "dropdown" },
    git_files = { theme = "dropdown" },
    todos = { theme = "dropdown" },
  },
}

