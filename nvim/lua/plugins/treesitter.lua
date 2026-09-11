return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "vim",
      "lua",
      "vimdoc",
      "html",
      "css",
      "typescript",
      "javascript",
      "tsx",
      "vue",
      "markdown",
      "markdown_inline",
      "json",
      "yaml",
      "toml",
      "regex",
      "bash",
    },
  },
  -- On the `main` branch `ensure_installed` is not a setup option -- setup only
  -- takes `install_dir`. Parsers are installed explicitly, and the install is
  -- what copies each language's queries next to them; a parser without its
  -- queries attaches a highlighter that paints nothing.
  config = function(_, opts)
    local ts = require "nvim-treesitter"
    local installed = ts.get_installed()

    local missing = vim.tbl_filter(function(lang)
      return not vim.tbl_contains(installed, lang)
    end, opts.ensure_installed)

    if #missing > 0 then
      ts.install(missing, { summary = true })
    end
  end,
}
