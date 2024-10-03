return {
  "rbong/vim-flog",
  lazy = true,
  cmd = { "Flog", "Flogsplit", "Floggit" },
  dependencies = {
    "tpope/vim-fugitive",
  },
  config = function()
    vim.g.flog_permanent_default_opts = {
      date = 'relative',
    }
  end,
}
