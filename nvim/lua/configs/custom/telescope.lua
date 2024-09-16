require("telescope")
  .setup({
    defaults = {
      -- layout_strategy = "horizontal",
      sorting_strategy = "ascending",
      prompt_prefix = " ",
      selection_caret = " ",
      path_display = { "truncate" },
      file_ignore_patterns = { "node_modules", ".git" }, -- Ignore specific folders
    },
    pickers = {
      find_files = { theme = "dropdown" },
      buffers = { theme = "dropdown" },
      live_grep = { theme = "dropdown" },
      grep_string = { theme = "dropdown" },
      git_files = { theme = "dropdown" },
      todos = { theme = "dropdown" },
    },
  })
  -- require("telescope").load_extension "noice"
