local M = {}

local lsp_log_path = vim.lsp.log and vim.lsp.log.get_filename and vim.lsp.log.get_filename()
  or vim.lsp.get_log_path and vim.lsp.get_log_path()
  or ""

-- version-compatible diagnostic jump
local function diag_goto_next()
  if vim.diagnostic.jump then
    vim.diagnostic.jump { count = 1, float = true }
  else
    vim.diagnostic.goto_next()
  end
end

local function diag_goto_prev()
  if vim.diagnostic.jump then
    vim.diagnostic.jump { count = -1, float = true }
  else
    vim.diagnostic.goto_prev()
  end
end

M.config = function()
  lvim.builtin.which_key = {
    ---@usage disable which-key completely [not recommended]
    active = true,
    on_config_done = nil,
    setup = {
      preset = "classic",
      delay = function(ctx)
        return ctx.plugin and 0 or 200
      end,
      notify = false,
      plugins = {
        marks = false,
        registers = false,
        spelling = {
          enabled = true,
          suggestions = 20,
        },
        presets = {
          operators = false,
          motions = false,
          text_objects = false,
          windows = false,
          nav = false,
          z = false,
          g = false,
        },
      },
      icons = {
        breadcrumb = lvim.icons.ui.DoubleChevronRight,
        separator = lvim.icons.ui.BoldArrowRight,
        group = lvim.icons.ui.Plus,
      },
      win = {
        border = "single",
        padding = { 2, 2, 2, 2 },
      },
      layout = {
        height = { min = 4, max = 25 },
        width = { min = 20, max = 50 },
        spacing = 3,
        align = "left",
      },
      show_help = true,
      show_keys = true,
      disable = {
        ft = {},
        bt = { "TelescopePrompt" },
      },
    },

    -- NOTE: Prefer using : over <cmd> as the latter avoids going back in normal-mode.
    -- see https://neovim.io/doc/user/map.html#:map-cmd
    spec = {
      -- Top-level single-key mappings
      { "<leader>;", "<cmd>Alpha<CR>", desc = "Dashboard" },
      { "<leader>w", "<cmd>w!<CR>", desc = "Save" },
      { "<leader>q", "<cmd>confirm q<CR>", desc = "Quit" },
      {
        "<leader>/",
        "<Plug>(comment_toggle_linewise_current)",
        desc = "Comment toggle current line",
      },
      { "<leader>c", "<cmd>BufferKill<CR>", desc = "Close Buffer" },
      {
        "<leader>f",
        function()
          require("lvim.core.telescope.custom-finders").find_project_files { previewer = false }
        end,
        desc = "Find File",
      },
      { "<leader>h", "<cmd>nohlsearch<CR>", desc = "No Highlight" },
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Explorer" },

      -- Visual mode mappings
      {
        mode = "v",
        { "<leader>/", "<Plug>(comment_toggle_linewise_visual)", desc = "Comment toggle linewise (visual)" },
        { "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code Action" },
        { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset Hunk" },
        { "<leader>gs", "<cmd>Gitsigns stage_hunk<cr>", desc = "Stage Hunk" },
      },

      -- Buffers
      { "<leader>b", group = "Buffers" },
      { "<leader>bj", "<cmd>BufferLinePick<cr>", desc = "Jump" },
      { "<leader>bf", "<cmd>Telescope buffers previewer=false<cr>", desc = "Find" },
      { "<leader>bb", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous" },
      { "<leader>bn", "<cmd>BufferLineCycleNext<cr>", desc = "Next" },
      { "<leader>bW", "<cmd>noautocmd w<cr>", desc = "Save without formatting (noautocmd)" },
      { "<leader>be", "<cmd>BufferLinePickClose<cr>", desc = "Pick which buffer to close" },
      { "<leader>bh", "<cmd>BufferLineCloseLeft<cr>", desc = "Close all to the left" },
      { "<leader>bl", "<cmd>BufferLineCloseRight<cr>", desc = "Close all to the right" },
      { "<leader>bD", "<cmd>BufferLineSortByDirectory<cr>", desc = "Sort by directory" },
      { "<leader>bL", "<cmd>BufferLineSortByExtension<cr>", desc = "Sort by language" },

      -- Debug
      { "<leader>d", group = "Debug" },
      { "<leader>dt", "<cmd>lua require'dap'.toggle_breakpoint()<cr>", desc = "Toggle Breakpoint" },
      { "<leader>db", "<cmd>lua require'dap'.step_back()<cr>", desc = "Step Back" },
      { "<leader>dc", "<cmd>lua require'dap'.continue()<cr>", desc = "Continue" },
      { "<leader>dC", "<cmd>lua require'dap'.run_to_cursor()<cr>", desc = "Run To Cursor" },
      { "<leader>dd", "<cmd>lua require'dap'.disconnect()<cr>", desc = "Disconnect" },
      { "<leader>dg", "<cmd>lua require'dap'.session()<cr>", desc = "Get Session" },
      { "<leader>di", "<cmd>lua require'dap'.step_into()<cr>", desc = "Step Into" },
      { "<leader>do", "<cmd>lua require'dap'.step_over()<cr>", desc = "Step Over" },
      { "<leader>du", "<cmd>lua require'dap'.step_out()<cr>", desc = "Step Out" },
      { "<leader>dp", "<cmd>lua require'dap'.pause()<cr>", desc = "Pause" },
      { "<leader>dr", "<cmd>lua require'dap'.repl.toggle()<cr>", desc = "Toggle Repl" },
      { "<leader>ds", "<cmd>lua require'dap'.continue()<cr>", desc = "Start" },
      { "<leader>dq", "<cmd>lua require'dap'.close()<cr>", desc = "Quit" },
      { "<leader>dU", "<cmd>lua require'dapui'.toggle({reset = true})<cr>", desc = "Toggle UI" },

      -- Plugins
      { "<leader>p", group = "Plugins" },
      { "<leader>pi", "<cmd>Lazy install<cr>", desc = "Install" },
      { "<leader>ps", "<cmd>Lazy sync<cr>", desc = "Sync" },
      { "<leader>pS", "<cmd>Lazy clear<cr>", desc = "Status" },
      { "<leader>pc", "<cmd>Lazy clean<cr>", desc = "Clean" },
      { "<leader>pu", "<cmd>Lazy update<cr>", desc = "Update" },
      { "<leader>pp", "<cmd>Lazy profile<cr>", desc = "Profile" },
      { "<leader>pl", "<cmd>Lazy log<cr>", desc = "Log" },
      { "<leader>pd", "<cmd>Lazy debug<cr>", desc = "Debug" },

      -- Git
      { "<leader>g", group = "Git" },
      { "<leader>gg", "<cmd>lua require 'lvim.core.terminal'.lazygit_toggle()<cr>", desc = "Lazygit" },
      {
        "<leader>gj",
        "<cmd>lua require 'gitsigns'.nav_hunk('next', {navigation_message = false})<cr>",
        desc = "Next Hunk",
      },
      {
        "<leader>gk",
        "<cmd>lua require 'gitsigns'.nav_hunk('prev', {navigation_message = false})<cr>",
        desc = "Prev Hunk",
      },
      { "<leader>gl", "<cmd>lua require 'gitsigns'.blame_line()<cr>", desc = "Blame" },
      { "<leader>gL", "<cmd>lua require 'gitsigns'.blame_line({full=true})<cr>", desc = "Blame Line (full)" },
      { "<leader>gp", "<cmd>lua require 'gitsigns'.preview_hunk()<cr>", desc = "Preview Hunk" },
      { "<leader>gr", "<cmd>lua require 'gitsigns'.reset_hunk()<cr>", desc = "Reset Hunk" },
      { "<leader>gR", "<cmd>lua require 'gitsigns'.reset_buffer()<cr>", desc = "Reset Buffer" },
      { "<leader>gs", "<cmd>lua require 'gitsigns'.stage_hunk()<cr>", desc = "Stage Hunk" },
      { "<leader>gu", "<cmd>lua require 'gitsigns'.undo_stage_hunk()<cr>", desc = "Undo Stage Hunk" },
      { "<leader>go", "<cmd>Telescope git_status<cr>", desc = "Open changed file" },
      { "<leader>gb", "<cmd>Telescope git_branches<cr>", desc = "Checkout branch" },
      { "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Checkout commit" },
      { "<leader>gC", "<cmd>Telescope git_bcommits<cr>", desc = "Checkout commit(for current file)" },
      { "<leader>gd", "<cmd>Gitsigns diffthis HEAD<cr>", desc = "Git Diff" },

      -- LSP
      { "<leader>l", group = "LSP" },
      { "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code Action" },
      { "<leader>ld", "<cmd>Telescope diagnostics bufnr=0 theme=get_ivy<cr>", desc = "Buffer Diagnostics" },
      { "<leader>lw", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
      { "<leader>lf", "<cmd>lua require('lvim.lsp.utils').format()<cr>", desc = "Format" },
      { "<leader>li", "<cmd>LspInfo<cr>", desc = "Info" },
      { "<leader>lI", "<cmd>Mason<cr>", desc = "Mason Info" },
      { "<leader>lj", diag_goto_next, desc = "Next Diagnostic" },
      { "<leader>lk", diag_goto_prev, desc = "Prev Diagnostic" },
      { "<leader>ll", "<cmd>lua vim.lsp.codelens.run()<cr>", desc = "CodeLens Action" },
      { "<leader>lq", "<cmd>lua vim.diagnostic.setloclist()<cr>", desc = "Quickfix" },
      { "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename" },
      { "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
      { "<leader>lS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace Symbols" },
      { "<leader>le", "<cmd>Telescope quickfix<cr>", desc = "Telescope Quickfix" },

      -- LunarVim
      { "<leader>L", group = "LunarVim" },
      {
        "<leader>Lc",
        "<cmd>edit " .. get_config_dir() .. "/config.lua<cr>",
        desc = "Edit config.lua",
      },
      { "<leader>Ld", "<cmd>LvimDocs<cr>", desc = "View LunarVim's docs" },
      {
        "<leader>Lf",
        "<cmd>lua require('lvim.core.telescope.custom-finders').find_lunarvim_files()<cr>",
        desc = "Find LunarVim files",
      },
      {
        "<leader>Lg",
        "<cmd>lua require('lvim.core.telescope.custom-finders').grep_lunarvim_files()<cr>",
        desc = "Grep LunarVim files",
      },
      { "<leader>Lk", "<cmd>Telescope keymaps<cr>", desc = "View LunarVim's keymappings" },
      {
        "<leader>Li",
        "<cmd>lua require('lvim.core.info').toggle_popup(vim.bo.filetype)<cr>",
        desc = "Toggle LunarVim Info",
      },
      {
        "<leader>LI",
        "<cmd>lua require('lvim.core.telescope.custom-finders').view_lunarvim_changelog()<cr>",
        desc = "View LunarVim's changelog",
      },
      { "<leader>Ll", group = "logs" },
      {
        "<leader>Lld",
        "<cmd>lua require('lvim.core.terminal').toggle_log_view(require('lvim.core.log').get_path())<cr>",
        desc = "view default log",
      },
      {
        "<leader>LlD",
        "<cmd>lua vim.fn.execute('edit ' .. require('lvim.core.log').get_path())<cr>",
        desc = "Open the default logfile",
      },
      {
        "<leader>Lll",
        function()
          local path = vim.lsp.log and vim.lsp.log.get_filename and vim.lsp.log.get_filename()
            or vim.lsp.get_log_path and vim.lsp.get_log_path()
            or ""
          require("lvim.core.terminal").toggle_log_view(path)
        end,
        desc = "view lsp log",
      },
      {
        "<leader>LlL",
        function()
          local path = vim.lsp.log and vim.lsp.log.get_filename and vim.lsp.log.get_filename()
            or vim.lsp.get_log_path and vim.lsp.get_log_path()
            or ""
          vim.fn.execute("edit " .. path)
        end,
        desc = "Open the LSP logfile",
      },
      {
        "<leader>Lln",
        "<cmd>lua require('lvim.core.terminal').toggle_log_view(os.getenv('NVIM_LOG_FILE'))<cr>",
        desc = "view neovim log",
      },
      { "<leader>LlN", "<cmd>edit $NVIM_LOG_FILE<cr>", desc = "Open the Neovim logfile" },
      { "<leader>Lr", "<cmd>LvimReload<cr>", desc = "Reload LunarVim's configuration" },
      { "<leader>Lu", "<cmd>LvimUpdate<cr>", desc = "Update LunarVim" },

      -- Search
      { "<leader>s", group = "Search" },
      { "<leader>sb", "<cmd>Telescope git_branches<cr>", desc = "Checkout branch" },
      { "<leader>sc", "<cmd>Telescope colorscheme<cr>", desc = "Colorscheme" },
      { "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "Find File" },
      { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Find Help" },
      { "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "Find highlight groups" },
      { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
      { "<leader>sr", "<cmd>Telescope oldfiles<cr>", desc = "Open Recent File" },
      { "<leader>sR", "<cmd>Telescope registers<cr>", desc = "Registers" },
      { "<leader>st", "<cmd>Telescope live_grep<cr>", desc = "Text" },
      { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>sC", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>sl", "<cmd>Telescope resume<cr>", desc = "Resume last search" },
      {
        "<leader>sp",
        "<cmd>lua require('telescope.builtin').colorscheme({enable_preview = true})<cr>",
        desc = "Colorscheme with Preview",
      },

      -- Treesitter
      { "<leader>T", group = "Treesitter" },
      { "<leader>Ti", ":TSConfigInfo<cr>", desc = "Info" },
    },
  }
end

M.setup = function()
  local which_key = require "which-key"

  which_key.setup(lvim.builtin.which_key.setup)

  if lvim.builtin.which_key.spec then
    which_key.add(lvim.builtin.which_key.spec)
  end

  if lvim.builtin.which_key.on_config_done then
    lvim.builtin.which_key.on_config_done(which_key)
  end
end

return M
