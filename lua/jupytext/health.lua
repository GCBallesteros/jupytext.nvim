local M = {}

M.check = function()
  local health = vim.health
  health.start "jupytext.nvim"
  vim.fn.system "jupytext --version"

  if vim.v.shell_error == 0 then
    health.ok "Jupytext is available"
  else
    health.error("Jupytext is not available", "Install jupytext via `pip install jupytext`")
  end
end

return M
