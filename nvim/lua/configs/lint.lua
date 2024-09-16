require("lint").linters_by_ft = {
  javascript = { "eslint" },
  typescript = { "eslint" },
  typescriptreact = { "eslint" },
  javascriptreact = { "eslint" },
  vue = { "eslint" },
}

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    require("lint").try_lint()
  end,
})

require("tailwind-tools").setup {}
