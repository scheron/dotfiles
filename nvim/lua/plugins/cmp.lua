return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "onsails/lspkind.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local cmp = require "cmp"
    local devicons = require "nvim-web-devicons"

    local kind_icons = {
      Text = "",
      Method = "",
      Function = "ƒ",
      Constructor = "",
      Field = "",
      Variable = "",
      Class = "",
      Interface = "",
      Module = "",
      Property = "",
      Unit = "塞",
      Value = "",
      Enum = "",
      Keyword = "",
      Snippet = "",
      Color = "",
      Reference = "",
      File = "",
      Folder = "",
      EnumMember = "",
      Constant = "",
      Struct = "פּ",
      Event = "",
      Operator = "",
      TypeParameter = "",
    }

    cmp.setup {
      mapping = {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm { select = true }
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<C-e>"] = cmp.mapping.close(),
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm { select = true }
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<C-i>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            fallback()
          else
            cmp.complete()
          end
        end, { "i", "s" }),
      },

      sources = cmp.config.sources {
        { name = "buffer" },
        { name = "nvim_lsp" },
        { name = "path" },
      },

      formatting = {
        format = function(entry, vim_item)
          if entry.source.name == "path" then
            local icon, icon_color = devicons.get_icon(vim_item.kind)
            if icon then
              vim_item.kind = icon
            end
          else
            vim_item.kind = kind_icons[vim_item.kind] or vim_item.kind
          end

          vim_item.menu = ({
            buffer = "[Buffer]",
            nvim_lsp = "[LSP]",
            path = "[Path]",
          })[entry.source.name]

          return vim_item
        end,
      },
    }
  end,
}
