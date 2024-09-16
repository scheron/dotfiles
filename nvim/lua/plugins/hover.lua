return {
  {
    "lewis6991/hover.nvim",
    config = function()
      require("hover").setup {
        init = function()
          require "hover.providers.lsp"
        end,
        preview_opts = {
          border = "single",
        },
        preview_window = false,
        title = true,
      }
      vim.keymap.set("n", "<leader>i", require("hover").hover, { desc = "Show hover info" })
      vim.keymap.set("n", "<leader>I", require("hover").hover_select, { desc = "hover.nvim (select)" })
      vim.keymap.set("n", "<C-p>", function() require("hover").hover_switch "previous" end, { desc = "hover.nvim (previous source)" })
      vim.keymap.set("n", "<C-n>", function() require("hover").hover_switch "next" end, { desc = "hover.nvim (next source)" })
    end,
    lazy = false,
  },
}
