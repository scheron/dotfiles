return {
  "lewis6991/gitsigns.nvim",
  opts = function(_, opts)
    opts.current_line_blame = true
    opts.current_line_blame_opts = {
      delay = 300,
      virt_text_pos = "eol",
      ignore_whitespace = false,
    }
    return opts
  end,
}
