local commands = require "jupytext.commands"
local utils = require "jupytext.utils"

local M = {}

M.config = {
  style = "hydrogen",
  custom_language_formatting = {},
}

local write_to_ipynb = function(ipynb_filename, output_extension)
  local metadata = utils.get_ipynb_metadata(ipynb_filename)
  local jupytext_filename = utils.get_jupytext_file(ipynb_filename, output_extension)
  jupytext_filename = vim.fn.resolve(vim.fn.expand(jupytext_filename))

  vim.cmd.write({ jupytext_filename, bang = true })
  commands.run_jupytext_command(vim.fn.shellescape(jupytext_filename), {
    ["--update"] = "",
    ["--to"] = "ipynb",
    ["--output"] = vim.fn.shellescape(ipynb_filename),
  })
end

local cleanup = function(jupytext_filename, delete)
  if delete then
    vim.cmd.delete(vim.fn.resolve(vim.fn.expand(jupytext_filename)))
  end
end

local read_from_ipynb = function(ipynb_filename)
  local metadata = utils.get_ipynb_metadata(ipynb_filename)
  local ipynb_filename = vim.fn.resolve(vim.fn.expand(ipynb_filename))

  -- Decide output extension and style
  local to_extension_and_style
  local output_extension

  local custom_formatting = nil
  if utils.check_key(M.config.custom_language_formatting, metadata.language) then
    custom_formatting = M.config.custom_language_formatting[metadata.language]
  end

  if custom_formatting then
    output_extension = custom_formatting.extension
    to_extension_and_style = output_extension .. ":" .. custom_formatting.style
  else
    to_extension_and_style = "auto" .. ":" .. M.config.style
    output_extension = metadata.extension
  end

  local jupytext_filename = utils.get_jupytext_file(ipynb_filename, output_extension)
  local jupytext_file_exists = vim.fn.filereadable(jupytext_filename) == 1
  -- filename is the notebook
  local filename_exists = vim.fn.filereadable(ipynb_filename)

  if filename_exists and not jupytext_file_exists then
    commands.run_jupytext_command(vim.fn.shellescape(ipynb_filename), {
      ["--to"] = to_extension_and_style,
      ["--output"] = vim.fn.shellescape(jupytext_filename),
    })
  end

  -- This is when the magic happens and we read the new file into the buffer
  if vim.fn.filereadable(jupytext_filename) then
    local jupytext_content = vim.fn.readfile(jupytext_filename)

    -- Replace the buffer content with the jupytext content
    vim.fn.setline(1, jupytext_content)
  else
    error "Couldn't find jupytext file."
    return
  end

  -- If jupytext version already existed then don't delete otherwise consider
  -- it to be sort of a temp file.
  local should_delete = not jupytext_file_exists
  vim.api.nvim_create_autocmd("BufUnload", {
    pattern = "<buffer>",
    group = "jupytext-nvim",
    callback = function(ev)
      cleanup(ev.match, should_delete)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd" }, {
    pattern = "<buffer>",
    group = "jupytext-nvim",
    callback = function(ev)
      write_to_ipynb(ev.match, output_extension)
    end,
  })

  local ft = nil
  if custom_formatting then
    if custom_formatting.force_ft then
      ft = metadata.language
    end
  end
  if not ft then
    ft = output_extension
  end

  vim.api.nvim_command("setlocal fenc=utf-8 ft=" .. ft)

  -- In order to make :undo a no-op immediately after the buffer is read, we
  -- need to do this dance with 'undolevels'.  Actually discarding the undo
  -- history requires performing a change after setting 'undolevels' to -1 and,
  -- luckily, we have one we need to do (delete the extra line from the :r
  -- command)
  -- (Comment straight from goerz/jupytext.vim)
  local levels = vim.o.undolevels
  vim.o.undolevels = -1
  vim.api.nvim_command "silent 1delete"
  vim.o.undolevels = levels

  -- First time we enter the buffer redraw. Don't know why but jupytext.vim was
  -- doing it. Apply Chesterton's fence principle.
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "<buffer>",
    group = "jupytext-nvim",
    once = true,
    command = "redraw",
  })
end

M.setup = function(config)
  vim.validate({ config = { config, "table", true } })
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  vim.validate({
    style = { M.config.style, "string" },
  })

  vim.api.nvim_create_augroup("jupytext-nvim", { clear = true })
  vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = { "*.ipynb" },
    group = "jupytext-nvim",
    callback = function(ev)
      read_from_ipynb(ev.match)
    end,
  })

  -- If we are using LazyVim make sure to run the LazyFile event so that the LSP
  -- and other important plugins get going
  if pcall(require, "lazy") then
    vim.api.nvim_exec_autocmds("User", { pattern = "LazyFile", modeline = false })
  end
end

return M
