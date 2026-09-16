local M = {}

local function get_link_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col   = vim.api.nvim_win_get_cursor(0)[2] -- 0-indexed byte offset

  local search_from = 1
  while true do
    local ls, le = line:find('%[%[', search_from)
    if not ls then return nil end
    local rs, re = line:find('%]%]', le + 1)
    if not rs then return nil end
    if col >= ls - 1 and col < re then
      return line:sub(ls, re) -- full [[...]] string
    end
    search_from = re + 1
  end
end

local function parse_link(raw)
  local content = raw:sub(3, -3) -- strip [[ and ]]

  -- Strip alias; only the target matters for navigation
  local pipe = content:find('|', 1, true)
  local target = pipe and content:sub(1, pipe - 1) or content

  local hash = target:find('#', 1, true)
  if not hash then
    return { file = target, heading = '', heading_level = 0 }
  end

  local file    = target:sub(1, hash - 1)
  local rest    = target:sub(hash) -- e.g. "#My Heading" or "##Sub"
  local hashes  = rest:match('^(#+)')
  local level   = hashes and #hashes or 0
  local heading = rest:sub(level + 1)
  return { file = file, heading = heading, heading_level = level }
end

local function resolve_file(file, vault, callback)
  -- Same-file reference [[#heading]]
  if file == '' then
    callback(vim.api.nvim_buf_get_name(0))
    return
  end

  local fname = file:match('%.md$') and file or (file .. '.md')
  local dir   = vim.fn.expand('%:p:h')

  -- 1. Local directory
  local local_path = dir .. '/' .. fname
  if vim.fn.filereadable(local_path) == 1 then
    callback(local_path)
    return
  end

  -- 2. Vault root
  local rooted = vault .. '/' .. fname
  if vim.fn.filereadable(rooted) == 1 then
    callback(rooted)
    return
  end

  -- 3. Global search
  local matches = vim.fn.globpath(vault, '**/' .. fname, 0, 1)

  if #matches == 0 then
    callback(nil)
    return
  end

  if #matches == 1 then
    callback(matches[1])
    return
  end

  -- Multiple matches: vim.ui.select so fzf-lua (or any picker) can intercept
  vim.ui.select(matches, {
    prompt      = 'Ambiguous link: ' .. fname,
    format_item = function(m)
      return m:gsub('^' .. vim.pesc(vault) .. '/?', '')
    end,
  }, function(choice)
    callback(choice) -- nil when the user cancels
  end)
end

local function jump_to_heading(parsed)
  if not parsed.heading or parsed.heading == '' then return end
  local hashes  = string.rep('#', parsed.heading_level)
  local text    = vim.fn.escape(parsed.heading, '.*[]\\')
  vim.fn.search('^' .. hashes .. '\\s\\+' .. text, 'w')
end

function M.follow_link(edit_method)
  local vault = vim.b.obsidian_vault_root
  if not vault or vault == '' then return end

  local raw = get_link_under_cursor()
  if not raw then return end

  local parsed = parse_link(raw)

  resolve_file(parsed.file, vault, function(file)
    if not file then return end
    local method = (not edit_method or edit_method == '') and 'edit' or edit_method
    vim.cmd(method .. ' ' .. vim.fn.fnameescape(file))
    jump_to_heading(parsed)
  end)
end

return M
