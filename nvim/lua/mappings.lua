require "nvchad.mappings"

local map = vim.keymap.set

-- Override NVChad default mappings
map("n", "s", "<nop>", { desc = "Disable current s mapping" })
map("n", "s", "cl", { desc = "Delete character and enter insert mode" })
map("n", "<S-s>", "<nop>", { desc = "Disable current S mapping" })
map("n", "<S-s>", "cc", { desc = "Delete line and enter insert mode" })
map('i', '<Down>', function() require('cmp').select_next_item() end, { silent = true, desc = "Select next item in completion menu" })
map('i', '<Up>', function() require('cmp').select_prev_item() end, { silent = true, desc = "Select previous item in completion menu" })

-- Yank and paste
map("v", "y", "ygv<esc>", { desc = "Yank and stay in visual mode" })


map("v", "<S-j>", "mz:m+<CR>`zgv", { noremap = true, silent = true, desc = "Move line down and keep selection" })
map("v", "<S-k>", "mz:m-2<CR>`zgv", { noremap = true, silent = true, desc = "Move line up and keep selection" })
map("n", "<S-j>", "mzJ`z", { desc = "Join line without moving cursor" })


-- Buffers
map("n", "<S-h>", ":bprevious<CR>", { desc = "Prev Buffer" })
map("n", "<S-l>", ":bnext<CR>", { desc = "Next Buffer" })
map("n", "<S-Tab>", ":bprevious<CR>", { desc = "Prev Buffer" })
map("n", "<Tab>", ":bnext<CR>", { desc = "Next Buffer" })
map("n", "<leader>x", "<cmd>:bd<CR>", { desc = "Close buffer" })
map("n", "<leader>cx", function() require("nvchad.tabufline").closeAllBufs() end, { desc = "Close All Buffers" })

-- Splits
map("n", "<leader>s", "<cmd>:split  <CR>", { desc = "Horizontal Split" })
map("n", "<leader>v", "<cmd>:vsplit <CR>", { desc = "Vertical Split" })

-- Telescope
map("n", "<leader>ft", "<cmd>TodoTelescope<CR>", { desc = "Find Todo" })
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "Find Word" })
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find File" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Find Buffer" })
map("n", "<leader>fc", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "Find in current file" })
map("n", "<leader>fg", "<cmd>Telescope git_commits<CR>", { desc = "Find Commit" })

-- Git
map("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "Open Lazygit" })
map("n", "<leader>g?", ":DiffviewFileHistory<CR>", { desc = "Git File History" })
map("n", "<leader>go", ":DiffviewOpen HEAD~1<CR>", { desc = "Git Last Commit" })
map("n", "<leader>gh", ":Flog<CR>", { desc = "Git Graph" })

-- Diagnostics
map("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "Show Diagnostics" })

-- Terminal
map("n", "<C-]>", function() require("nvchad.term").toggle { pos = "vsp", size = 0.4 } end, { desc = "Toogle Terminal Vertical" })
map("n", "<C-\\>", function() require("nvchad.term").toggle { pos = "sp", size = 0.4 } end, { desc = "Toogle Terminal Horizontal" })
map("n", "<C-f>", function() require("nvchad.term").toggle { pos = "float" } end, { desc = "Toogle Terminal Float" })
map("t", "<C-]>", function() require("nvchad.term").toggle { pos = "vsp" } end, { desc = "Toogle Terminal Vertical" })
map("t", "<C-\\>", function() require("nvchad.term").toggle { pos = "sp" } end, { desc = "Toogle Terminal Horizontal" })
map("t", "<C-f>", function() require("nvchad.term").toggle { pos = "float" } end, { desc = "Toogle Terminal Float" })

-- Basic
map("i", "jj", "<ESC>")
map("i", "jk", "<ESC>")
map("n", "<leader>w", "<cmd>:w<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>:q<CR>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>:q!<CR>", { desc = "Force Quit" })
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "<C-g>", function() return vim.fn["codeium#Accept"]() end, { expr = true })


-- Good to have
map("n", "<leader>p", function() require("conform").format { lsp_fallback = true } end, { desc = "Format File" })

-- NOTE: NvimTree
-- Show hidden files <S-h>
-- Show git ignored files <S-i>
