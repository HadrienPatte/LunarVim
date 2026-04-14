local M = {}

M.config = function()
  lvim.builtin.indentlines = {
    active = true,
    on_config_done = nil,
    options = {
      enabled = true,
      exclude = {
        buftypes = { "terminal", "nofile" },
        filetypes = {
          "help",
          "startify",
          "dashboard",
          "lazy",
          "neogitstatus",
          "NvimTree",
          "Trouble",
          "text",
        },
      },
      indent = {
        char = lvim.icons.ui.LineLeft,
      },
      scope = {
        char = lvim.icons.ui.LineLeft,
        show_start = true,
        show_end = false,
      },
    },
  }
end

M.setup = function()
  local status_ok, ibl = pcall(require, "ibl")
  if not status_ok then
    return
  end

  ibl.setup(lvim.builtin.indentlines.options)

  if lvim.builtin.indentlines.on_config_done then
    lvim.builtin.indentlines.on_config_done()
  end
end

return M
