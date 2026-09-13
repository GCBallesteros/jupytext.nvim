local commands = require "jupytext.commands"
local utils = require "jupytext.utils"

local M = {}

M.config = {
  style = "hydrogen",
  output_extension = "auto",
  force_ft = nil,
  custom_language_formatting = {},
}

local write_to_ipynb = function(event, output_extension)
  local ipynb_filename = event.match
  local jupytext_filename = utils.get_jupytext_file(ipynb_filename, output_extension)
  jupytext_filename = vim.fn.resolve(vim.fn.expand(jupytext_filename))

  vim.cmd.write({ jupytext_filename, bang = true })
  commands.run_jupytext_command(vim.fn.shellescape(jupytext_filename), {
    ["--update"] = "",
    ["--to"] = "ipynb",
    ["--output"] = vim.fn.shellescape(ipynb_filename),
  })
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("modified", false, { buf = buf })

  local post_write = "BufWritePost"
  if event.event == "FileWriteCmd" then
    post_write = "FileWritePost"
  end
  vim.api.nvim_exec_autocmds(post_write, { pattern = ipynb_filename })
end

local style_and_extension = function(metadata)
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
    if M.config.output_extension == "auto" then
      output_extension = metadata.extension
    else
      output_extension = M.config.output_extension
    end
    to_extension_and_style = M.config.output_extension .. ":" .. M.config.style
  end

  return custom_formatting, output_extension, to_extension_and_style
end

local cleanup = function(ipynb_filename, delete)
  local metadata = utils.get_ipynb_metadata(ipynb_filename)

  local _, output_extension, _ = style_and_extension(metadata)

  local jupytext_filename = utils.get_jupytext_file(ipynb_filename, output_extension)
  if delete then
    vim.fn.delete(vim.fn.resolve(vim.fn.expand(jupytext_filename)))
  end
end

-- Resolve the filetype the notebook buffer should get, from config and metadata.
local resolve_filetype = function(metadata, custom_formatting)
  local ft = M.config.force_ft

  if custom_formatting ~= nil then
    if custom_formatting.force_ft then
      if custom_formatting.style == "quarto" then
        ft = "quarto"
      else
        -- just let the user set whatever ft they want
        ft = custom_formatting.force_ft
      end
    end
  end

  if not ft then
    ft = metadata.language
  end

  return ft
end

local read_from_ipynb = function(ipynb_filename)
  local metadata = utils.get_ipynb_metadata(ipynb_filename)
  local ipynb_filename = vim.fn.resolve(vim.fn.expand(ipynb_filename))

  -- Decide output extension and style
  local custom_formatting, output_extension, to_extension_and_style = style_and_extension(metadata)

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

  -- Resolve the target filetype up front and advertise it on the buffer, so that
  -- when the read events below fire Neovim's filetype detection, the rule we
  -- register in M.setup resolves this *.ipynb buffer to the notebook's language
  -- instead of the built-in ipynb->json mapping.
  local ft = resolve_filetype(metadata, custom_formatting)
  vim.b.jupytext_filetype = ft

  -- This is when the magic happens and we read the new file into the buffer
  if vim.fn.filereadable(jupytext_filename) then
    local jupytext_content = vim.fn.readfile(jupytext_filename)

    -- Need to add an extra line so that the undo dance that comes later on
    -- doesn't delete the first line of the actual input
    table.insert(jupytext_content, 1, "")

    -- Our BufReadCmd for *.ipynb replaces the normal read, so the BufReadPre,
    -- BufReadPost and FileType events that a plain :edit would fire are all
    -- suppressed. Re-emit them here, in a normal read's order, so plugins that
    -- lazy-load on file events still start when a notebook is the first file
    -- opened. BufReadPre fires now, while the buffer is still empty (as a real
    -- read would), before the filetype is set below.
    vim.api.nvim_exec_autocmds("BufReadPre", { modeline = false })

    -- Replace the buffer content with the jupytext content
    vim.api.nvim_buf_set_lines(0, 0, -1, false, jupytext_content)
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
      write_to_ipynb(ev, output_extension)
    end,
  })

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

  vim.api.nvim_command "setlocal fenc=utf-8"

  -- BufReadPost fires now that the buffer holds the converted content. Neovim's
  -- built-in filetype detection runs on this event and, via the rule registered
  -- in M.setup, resolves this notebook to its language -- firing a single, correct
  -- FileType (no spurious `json`). The BufReadPre-loaded plugins (e.g. LSP) and
  -- the BufReadPost-loaded plugins (treesitter, linters) then attach exactly as
  -- they would for a normally-read file.
  vim.api.nvim_exec_autocmds("BufReadPost", { modeline = false })

  -- Fallback for when filetype detection is disabled (`:filetype off`): `setf`
  -- only sets the filetype if it wasn't set already, so it never double-fires
  -- FileType when detection above already set it. `ft` is nil only for a
  -- notebook whose metadata yields no language, which fails earlier anyway.
  if ft then
    vim.api.nvim_command("setf " .. ft)
  end

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
    output_extension = { M.config.output_extension, "string" },
  })

  -- Teach Neovim's filetype detection that a notebook buffer holds its source
  -- language, not json (the built-in `ipynb = 'json'` mapping). read_from_ipynb
  -- stashes the resolved filetype on the buffer as `b:jupytext_filetype`; this
  -- returns it so that when the read events fire, detection produces the correct
  -- FileType with no spurious json. For any buffer jupytext did not prepare it
  -- returns "json", preserving Neovim's built-in behaviour (this rule replaces
  -- the built-in `ipynb` extension entry, so it must reinstate that default).
  -- `extension` is the lowest-priority match category, so a user's own filename
  -- or pattern rule for `*.ipynb` still takes precedence over this.
  vim.filetype.add({
    extension = {
      ipynb = function(_, buf)
        local ok, ft = pcall(function()
          return vim.b[buf].jupytext_filetype
        end)
        if ok and ft then
          return ft
        end
        return "json"
      end,
    },
  })

  vim.api.nvim_create_augroup("jupytext-nvim", { clear = true })
  vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = { "*.ipynb" },
    group = "jupytext-nvim",
    callback = function(ev)
      read_from_ipynb(ev.match)
    end,
  })
end

return M
