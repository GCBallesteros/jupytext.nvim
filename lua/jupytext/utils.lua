local M = {}

local language_extensions = {
  python = "py",
  julia = "jl",
  r = "r",
  R = "r",
  bash = "sh",
}

local language_names = {
  python3 = "python",
}

M.get_ipynb_metadata = function(filename)
  local metadata = vim.json.decode(io.open(filename, "r"):read "a")["metadata"]
  local language

  if metadata.kernelspec then
    language = metadata.kernelspec.language
    if not language and metadata.kernelspec.name then
      language = language_names[metadata.kernelspec.name]
    end
  end

  if not language and metadata.jupytext then
    language = metadata.jupytext.main_language
  end

  if not language and metadata.language_info then
    language = metadata.language_info.name
  end

  if not language and metadata["application/vnd.databricks.v1+notebook"] then
    language = metadata["application/vnd.databricks.v1+notebook"].language
  end

  local extension = language_extensions[language]

  return { language = language, extension = extension }
end

M.get_jupytext_file = function(filename, extension)
  if extension == nil then
    error("Could not determine a jupytext file extension for " .. filename)
  end
  local fileroot = vim.fn.fnamemodify(filename, ":r")
  return fileroot .. "." .. extension
end

M.check_key = function(tbl, key)
  for tbl_key, _ in pairs(tbl) do
    if tbl_key == key then
      return true
    end
  end

  return false
end

return M
