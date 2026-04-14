local M = {}
local Log = require "lvim.core.log"

local has_tree_sitter_cli = nil

function M.config()
  lvim.builtin.treesitter = {
    on_config_done = nil,

    -- A list of parser names to ensure are installed
    ensure_installed = { "comment", "markdown_inline", "regex" },

    -- Automatically install missing parsers when entering buffer
    auto_install = true,

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

--- Check if the tree-sitter CLI is available (cached)
local function check_tree_sitter_cli()
  if has_tree_sitter_cli == nil then
    has_tree_sitter_cli = vim.fn.executable "tree-sitter" == 1
  end
  return has_tree_sitter_cli
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
    if check_tree_sitter_cli() then
      nvim_treesitter.install(parsers)
    else
      Log:warn "tree-sitter CLI not found, skipping parser installation. Install it with: brew install tree-sitter-cli"
    end
  end

  -- Register common filetype aliases so treesitter can highlight them
  -- using a related parser (the new nvim-treesitter main branch does not
  -- do this automatically like the old master branch did)
  local ft_to_parser = {
    helm = "yaml",
    dotenv = "bash",
    zsh = "bash",
    keymap = "devicetree",
    json5 = "json",
    jsonc = "json",
    terraform = "hcl",
  }
  for ft, parser in pairs(ft_to_parser) do
    pcall(vim.treesitter.language.register, parser, ft)
  end

  -- Build a set of available parsers for auto-install lookups
  local available_parsers = {}
  local get_available_ok, available_list = pcall(nvim_treesitter.get_available)
  if get_available_ok and available_list then
    for _, p in ipairs(available_list) do
      available_parsers[p] = true
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

  -- Track parsers we've already kicked off auto-install for
  local auto_installing = {}

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("lvim_treesitter", { clear = true }),
    callback = function(ev)
      local buf = ev.buf
      local lang = vim.treesitter.language.get_lang(ev.match) or ev.match

      -- Check if a parser exists for this language
      local parser_ok = pcall(vim.treesitter.language.inspect, lang)

      -- Auto-install: if parser not present but available, install then re-trigger
      if not parser_ok then
        if
          lvim.builtin.treesitter.auto_install
          and check_tree_sitter_cli()
          and available_parsers[lang]
          and not auto_installing[lang]
        then
          auto_installing[lang] = true
          Log:debug("auto-installing treesitter parser for: " .. lang)
          local task = nvim_treesitter.install { lang }
          if task and task.wait then
            task:wait(60000)
            -- Re-trigger FileType so highlighting activates after install
            vim.schedule(function()
              vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
            end)
          end
        end
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
