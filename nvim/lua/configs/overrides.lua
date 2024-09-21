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
    "tsserver",
    "prettier",
    "eslint_d",
    "clangd",
    "clang-format",
    "node-debug2-adapter",
    "vue-language-server",
    "shellcheck",
    "tailwindcss-language-server",
  },
  handlers = {
    -- lsp_zero.default_setup,
    function(server_name)
      if server_name == "tsserver" then
        server_name = "ts_ls"
      else
        lsp_zero.default_setup(server_name)
      end
    end,
  },
}

return M
