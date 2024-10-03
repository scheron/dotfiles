return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "onsails/lspkind.nvim",
    "nvim-tree/nvim-web-devicons",
    {
      "supermaven-inc/supermaven-nvim",
      event = "VimEnter",
      config = function()
        require("supermaven-nvim").setup {
          disable_keymaps = true,
        }
      end,
    },
  },
  config = function()
    local cmp = require "cmp"
    local devicons = require "nvim-web-devicons"
    local supermaven = require "supermaven-nvim.completion_preview" 

    local kind_icons = {
      Text = "",
      Method = "",
      Function = "ƒ",
      Constructor = "",
      Field = "",
      Variable = "",
      Class = "",
      Interface = "",
      Module = "",
      Property = "",
      Unit = "塞",
      Value = "",
      Enum = "",
      Keyword = "",
      Snippet = "",
      Color = "",
      Reference = "",
      File = "",
      Folder = "",
      EnumMember = "",
      Constant = "",
      Struct = "פּ",
      Event = "",
      Operator = "",
      TypeParameter = "",
      Supermaven = "",
    }

    cmp.setup {
      mapping = {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm { select = true }
          elseif supermaven.has_suggestion() then
            supermaven.on_accept_suggestion()
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<C-e>"] = cmp.mapping.close(),
        ["<CR>"] = cmp.mapping.confirm { select = true },

        ["<C-i>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            if supermaven.has_suggestion() then
              supermaven.on_accept_suggestion()
              fallback()
            else
              fallback()
            end
          else
            cmp.complete()
          end
        end, { "i", "s" }),
      },

      sources = cmp.config.sources {
        { name = "supermaven" },
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
            supermaven = "[AI]",
          })[entry.source.name]

          return vim_item
        end,
      },
    }
  end,
}
