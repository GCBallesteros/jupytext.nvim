local M = {}

M.run_jupytext_command = function(input_file, options)
  local cmd = "jupytext " .. input_file .. " "
  for option_name, option_value in pairs(options) do
    cmd = cmd .. option_name .. "=" .. option_value .. " "
  end

  local output = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    print(output)
    vim.api.nvim_err_writeln(cmd .. ": " .. vim.v.shell_error)
    return
  end
end

return M
