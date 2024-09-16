local M = {}

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
    "vue",
  },
  indent = {
    enable = true,
  },
}

M.mason = {
  ensure_installed = {
    "lua-language-server",
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "prettier",
    "eslint_d",
    "clangd",
    "clang-format",
    "node-debug2-adapter",
    "vue-language-server",
    "shellcheck",
    "tailwindcss-language-server",
    "ts_ls"
  },
}

return M
