return {
  "supermaven-inc/supermaven-nvim",
  event = "VimEnter",
  config = function()
    require("supermaven-nvim").setup {}
  end,
}
