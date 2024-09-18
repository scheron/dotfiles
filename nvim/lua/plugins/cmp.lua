return {
  "hrsh7th/nvim-cmp",
  config = function()
    local cmp = require "cmp"

    cmp.setup {
      mapping = cmp.mapping.preset.insert {
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-i>"] = cmp.mapping(function(fallback)
          cmp.complete({
            config = {
              sources = {
                { name = "nvim_lsp" }, 
              },
            },
          })
        end),
        ["<CR>"] = cmp.mapping.confirm { select = true },

        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-k>"] = cmp.mapping.select_prev_item(),
      },
      sources = cmp.config.sources {
        { name = "nvim_lsp" },  -- Default: LSP completions
        { name = "nvim_lua" },  -- Lua completions for Neovim development
        { name = "path" },      -- File path completions
        { name = "buffer" },    -- Buffer completions
      },

      completion = {
        completeopt = "menu,menuone,noinsert",
      },

      formatting = {
        format = function(entry, vim_item)
          vim_item.kind = require("lspkind").presets.default[vim_item.kind]

          vim_item.menu = ({
            nvim_lsp = "[LSP]",
            buffer = "[Buffer]",
            nvim_lua = "[Lua]",
            path = "[Path]",
          })[entry.source.name]

          return vim_item
        end,
      },
    }
  end,
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-nvim-lua",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
  },
}
