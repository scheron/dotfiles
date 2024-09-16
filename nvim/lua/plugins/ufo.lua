return {
  {
    "kevinhwang91/nvim-ufo",
    event = "BufReadPost", 
    dependencies = {
      "kevinhwang91/promise-async",
    },
    config = function()
      require('ufo').setup({
        provider_selector = function(bufnr, filetype, buftype)
          return {'treesitter', 'indent'}
        end,
        fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
          local newVirtText = {}
          local suffix = ('  ↙ %d '):format(endLnum - lnum)  -- Diagonal down-left arrow with folded line count
          local sufWidth = vim.fn.strdisplaywidth(suffix)
          local targetWidth = width - sufWidth
          local curWidth = 0

          for _, chunk in ipairs(virtText) do
            local chunkText = chunk[1]
            local chunkWidth = vim.fn.strdisplaywidth(chunkText)
            if targetWidth > curWidth + chunkWidth then
              table.insert(newVirtText, chunk)
              curWidth = curWidth + chunkWidth
            else
              chunkText = truncate(chunkText, targetWidth - curWidth)
              local hlGroup = chunk[2]
              table.insert(newVirtText, {chunkText, hlGroup})
              curWidth = curWidth + vim.fn.strdisplaywidth(chunkText)
              if curWidth < targetWidth then
                suffix = suffix .. string.rep(' ', targetWidth - curWidth)
              end
              break
            end
          end
          table.insert(newVirtText, {suffix, 'MoreMsg'})  -- Add the diagonal arrow at the end
          return newVirtText
        end
      })

      -- Fold settings
      vim.o.foldcolumn = '0'        -- Disable fold column on the left
      vim.o.foldlevel = 99          -- Start with all folds open
      vim.o.foldlevelstart = 99     -- Ensure folds are open when loading
      vim.o.foldenable = true       -- Enable folding globally

      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)   -- Open all folds
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)  -- Close all folds
    end,
  },
}
