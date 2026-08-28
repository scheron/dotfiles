return {
  "ChmaraX/herdr-nvim",
  cond = function()
    return vim.env.HERDR_ENV ~= nil
  end,
  event = "VeryLazy",
  opts = {},
}
