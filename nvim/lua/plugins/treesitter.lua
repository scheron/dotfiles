return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  opts = {
    fold = {
      enable = true,
    },
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
}
