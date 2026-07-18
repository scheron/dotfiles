local nvlsp = require "nvchad.configs.lspconfig"

nvlsp.defaults()

local servers = { "html", "ts_ls", "vue_ls", "cssls", "clangd", "gradle_ls" }
vim.lsp.enable(servers)

-- vue_ls (Vue 3 language server) runs in hybrid mode: it delegates TypeScript to
-- ts_ls, which must attach to .vue files and load @vue/typescript-plugin.
local vue_language_server_path = vim.fn.stdpath "data"
  .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

vim.lsp.config("ts_ls", {
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  single_file_support = true,
  init_options = {
    plugins = {
      {
        name = "@vue/typescript-plugin",
        location = vue_language_server_path,
        languages = { "vue" },
      },
    },
  },
  commands = {
    OrganizeImports = {
      function()
        local params = {
          command = "_typescript.organizeImports",
          arguments = { vim.api.nvim_buf_get_name(0) },
          title = "",
        }
        vim.lsp.buf_request(0, "workspace/executeCommand", params)
      end,
      description = "Organize Imports",
    },
  },
})

vim.lsp.config("emmet_language_server", {
  filetypes = {
    "html",
    "css",
    "scss",
    "less",
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    "vue",
    "svelte",
  },
})
vim.lsp.enable "emmet_language_server"
