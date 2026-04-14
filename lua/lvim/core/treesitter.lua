local M = {}
local Log = require "lvim.core.log"

function M.config()
  lvim.builtin.treesitter = {
    on_config_done = nil,

    -- A list of parser names to ensure are installed
    ensure_installed = { "comment", "markdown_inline", "regex" },

    -- Enable treesitter-based highlighting
    highlight = {
      enable = true,
      -- Languages to disable highlighting for
      disable = { "latex" },
    },

    -- Enable treesitter-based indentation (experimental)
    indent = {
      enable = true,
      -- Languages to disable indentation for
      disable = { "yaml", "python" },
    },

    -- Context commentstring configuration
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
      config = {
        typescript = "// %s",
        css = "/* %s */",
        scss = "/* %s */",
        html = "<!-- %s -->",
        svelte = "<!-- %s -->",
        vue = "<!-- %s -->",
        json = "",
      },
    },
  }
end

function M.setup()
  -- avoid running in headless mode since it's harder to detect failures
  if #vim.api.nvim_list_uis() == 0 then
    Log:debug "headless mode detected, skipping running setup for treesitter"
    return
  end

  local ts_ok, nvim_treesitter = pcall(require, "nvim-treesitter")
  if not ts_ok then
    Log:error "Failed to load nvim-treesitter"
    return
  end

  -- Setup context commentstring if available
  local status_ok, ts_context_commentstring = pcall(require, "ts_context_commentstring")
  if status_ok then
    ts_context_commentstring.setup(lvim.builtin.treesitter.context_commentstring or {})
  end

  -- Install requested parsers (async, runs in background)
  -- Requires the tree-sitter CLI (>= 0.26.1) to compile parsers
  local parsers = lvim.builtin.treesitter.ensure_installed
  if parsers and #parsers > 0 then
    if vim.fn.executable "tree-sitter" == 1 then
      nvim_treesitter.install(parsers)
    else
      Log:warn "tree-sitter CLI not found, skipping parser installation. Install it with: brew install tree-sitter-cli"
    end
  end

  -- Enable highlighting and indentation per-filetype via autocmd
  local highlight_cfg = lvim.builtin.treesitter.highlight or {}
  local indent_cfg = lvim.builtin.treesitter.indent or {}

  local function is_disabled(cfg, lang, buf)
    local disable = cfg.disable
    if type(disable) == "table" then
      return vim.tbl_contains(disable, lang)
    elseif type(disable) == "function" then
      return disable(lang, buf)
    end
    return false
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("lvim_treesitter", { clear = true }),
    callback = function(ev)
      local buf = ev.buf
      local lang = vim.treesitter.language.get_lang(ev.match) or ev.match

      -- Check if a parser exists for this language
      local parser_ok = pcall(vim.treesitter.language.inspect, lang)
      if not parser_ok then
        return
      end

      -- Check for bigfile disable
      local bigfile_ok, big_file_detected = pcall(vim.api.nvim_buf_get_var, buf, "bigfile_disable_treesitter")
      if bigfile_ok and big_file_detected then
        return
      end

      -- Enable highlighting
      if highlight_cfg.enable and not is_disabled(highlight_cfg, lang, buf) then
        pcall(vim.treesitter.start, buf, lang)
      end

      -- Enable indentation
      if indent_cfg.enable and not is_disabled(indent_cfg, lang, buf) then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end,
  })

  if lvim.builtin.treesitter.on_config_done then
    lvim.builtin.treesitter.on_config_done(nvim_treesitter)
  end
end

return M
