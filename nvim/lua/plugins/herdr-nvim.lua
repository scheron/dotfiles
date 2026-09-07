-- Code annotations you send to a herdr agent. Only the nvim half of
-- ChmaraX/herdr-nvim is used: it talks to herdr over the CLI (`herdr agent
-- list`, `herdr pane send-text`, `herdr agent prompt`), so the herdr-side
-- plugin — the sidebar and the file picker — is deliberately not installed.
--
-- Keymaps are bound here rather than left to the plugin's defaults so the
-- visual-mode binding is explicit and a second setup() can never fight over
-- them (`keymaps = false` makes setup() bind nothing).
return {
  "ChmaraX/herdr-nvim",
  cond = function()
    return vim.env.HERDR_ENV ~= nil
  end,
  event = "VeryLazy",
  opts = { keymaps = false },
  config = function(_, opts)
    local hn = require("herdr-nvim")
    hn.setup(opts)

    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { desc = "herdr: " .. desc })
    end

    map("n", "<leader>ac", hn.comment_line, "comment line")
    map("x", "<leader>ac", hn.comment_selection, "comment selection")
    map("n", "<leader>al", hn.list_comments, "list comments")
    map("n", "<leader>as", function()
      hn.send_all({ submit = false })
    end, "paste comments to agent")
    map("n", "<leader>aS", function()
      hn.send_all({ submit = true })
    end, "send comments to agent")
  end,
}
