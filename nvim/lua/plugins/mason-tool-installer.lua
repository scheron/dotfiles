return {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  event = "VeryLazy",
  dependencies = { "mason.nvim" },
  opts = {
    ensure_installed = {
      "typescript-language-server",
      "vue-language-server",
      "html-lsp",
      "css-lsp",
      "emmet-language-server",
      "clangd",
      "gradle-language-server",
      "stylua",
      "prettierd",
      "prettier",
    },
    run_on_start = true,
  },
}
