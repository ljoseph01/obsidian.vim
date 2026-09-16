local M = {}

-- Called from Vimscript when a link resolves to multiple files.
-- callback is the Vimscript Funcref that opens the chosen file.
function M.pick(matches, fname, callback)
  local vault = vim.b.obsidian_vault_root or ''
  vim.ui.select(matches, {
    prompt      = 'Ambiguous link: ' .. fname,
    format_item = function(m)
      return m:gsub('^' .. vim.pesc(vault) .. '/?', '')
    end,
  }, function(choice)
    if choice then callback(choice) end
  end)
end

return M
