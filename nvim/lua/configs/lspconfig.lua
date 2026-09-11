local nvlsp = require "nvchad.configs.lspconfig"

nvlsp.defaults()

vim.lsp.enable { "html", "cssls", "clangd", "gradle_ls" }

-- vue_ls (Vue 3 language server) runs in hybrid mode: it owns the template and
-- style blocks and delegates TypeScript to ts_ls, which must attach to .vue files
-- and load @vue/typescript-plugin.
local vue_language_server_path = vim.fn.stdpath "data"
  .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

local vue_plugin = {
  name = "@vue/typescript-plugin",
  location = vue_language_server_path,
  languages = { "vue" },
  configNamespace = "typescript",
}

-- TypeScript 7 is the native Go compiler: it ships no tsserver.js and no
-- programmatic API, so neither ts_ls nor @vue/typescript-plugin can drive it.
-- Such projects get `tsc --lsp` instead -- except Vue ones, which Volar still
-- pins to the TypeScript 6 line.
local function has_native_typescript(root)
  local ts = root .. "/node_modules/typescript"
  return vim.uv.fs_stat(ts) ~= nil and vim.uv.fs_stat(ts .. "/lib/tsserver.js") == nil
end

local function is_vue_project(root)
  if vim.uv.fs_stat(root .. "/node_modules/vue") then
    return true
  end
  local ok, lines = pcall(vim.fn.readfile, root .. "/package.json")
  if not ok then
    return false
  end
  local decoded, pkg = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded or type(pkg) ~= "table" then
    return false
  end
  return (pkg.dependencies or {}).vue ~= nil or (pkg.devDependencies or {}).vue ~= nil
end

local function needs_tsserver(root)
  return not has_native_typescript(root) or is_vue_project(root)
end

-- Wrap the upstream root_dir so the two servers stay mutually exclusive; without
-- this both attach and every diagnostic shows up twice.
local function only_when(server, accept)
  local root_dir = vim.lsp.config[server].root_dir
  return function(bufnr, on_dir)
    root_dir(bufnr, function(dir)
      if dir and accept(dir) then
        on_dir(dir)
      end
    end)
  end
end

vim.lsp.config("ts_ls", {
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  init_options = {
    plugins = { vue_plugin },
  },
  root_dir = only_when("ts_ls", needs_tsserver),
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

vim.lsp.config("tsc", {
  root_dir = only_when("tsc", function(root)
    return not needs_tsserver(root)
  end),
})

vim.lsp.enable { "ts_ls", "tsc", "vue_ls" }

-- Since 3.0.2 vue_ls emits its own `component` semantic token instead of leaving
-- custom tags to tsserver; no colourscheme defines the group yet.
vim.api.nvim_set_hl(0, "@lsp.type.component", { link = "@type" })

-- Emmet expands HTML abbreviations, so it only earns its place where markup can
-- appear. On plain .ts/.js it contributes nothing but noise in the completion
-- menu and in the statusline.
vim.lsp.config("emmet_language_server", {
  filetypes = {
    "html",
    "css",
    "scss",
    "less",
    "javascriptreact",
    "typescriptreact",
    "vue",
    "svelte",
  },
})
vim.lsp.enable "emmet_language_server"
