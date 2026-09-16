local M = {}

local ns = vim.api.nvim_create_namespace('obsidian_wiki_links')

-- Above treesitter (100) so re-parses never clobber us.
-- Inner marks (delim/sep/alias) sit one step higher to win over the base link colour.
local BASE     = 200
local INNER    = 201
local CONCEAL  = 202

local function setup_hl()
  vim.api.nvim_set_hl(0, 'ObsidianLink',      { default = true, link = 'Underlined' })
  vim.api.nvim_set_hl(0, 'ObsidianLinkDelim', { default = true, link = 'Comment' })
  vim.api.nvim_set_hl(0, 'ObsidianLinkSep',   { default = true, link = 'Comment' })
  vim.api.nvim_set_hl(0, 'ObsidianLinkAlias', { default = true, link = 'Title' })
end

local function mark(bufnr, row, c0, c1, group, priority)
  vim.api.nvim_buf_set_extmark(bufnr, ns, row, c0, {
    end_col  = c1,
    hl_group = group,
    priority = priority,
  })
end

local function conceal(bufnr, row, c0, c1)
  vim.api.nvim_buf_set_extmark(bufnr, ns, row, c0, {
    end_col  = c1,
    conceal  = '',
    priority = CONCEAL,
  })
end

local function apply(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for row, line in ipairs(lines) do
    local search_from = 1
    while true do
      local os, oe = line:find('%[%[', search_from)
      if not os then break end

      local cs, ce = line:find('%]%]', oe + 1)
      if not cs then break end

      -- Whole [[...]] region
      mark(bufnr, row - 1, os - 1, ce,    'ObsidianLink',      BASE)
      -- [[ and ]] delimiters
      mark(bufnr, row - 1, os - 1, oe,    'ObsidianLinkDelim', INNER)
      mark(bufnr, row - 1, cs - 1, ce,    'ObsidianLinkDelim', INNER)

      -- Optional | separator and alias
      local inner   = line:sub(oe + 1, cs - 1)
      local pipe    = inner:find('|', 1, true)
      if pipe then
        local pipe_abs = oe + pipe  -- 1-indexed absolute col
        mark(bufnr, row - 1, pipe_abs - 1, pipe_abs,  'ObsidianLinkSep',   INNER)
        mark(bufnr, row - 1, pipe_abs,     cs - 1,    'ObsidianLinkAlias', INNER)
        -- Conceal [[target| so only the alias is visible off-line
        conceal(bufnr, row - 1, os - 1,  pipe_abs)
        conceal(bufnr, row - 1, cs - 1,  ce)
      else
        -- No alias: conceal just the [[ and ]] brackets
        conceal(bufnr, row - 1, os - 1, oe)
        conceal(bufnr, row - 1, cs - 1, ce)
      end

      search_from = ce + 1
    end
  end
end

local function set_win_opts()
  vim.api.nvim_set_option_value('conceallevel', 2, { win = 0 })
  -- concealcursor='' means the cursor line is never concealed — you always
  -- see the raw [[target|alias]] when your cursor is on that line.
  vim.api.nvim_set_option_value('concealcursor', '', { win = 0 })
end

function M.attach(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  setup_hl()
  apply(bufnr)
  set_win_opts()

  local group = vim.api.nvim_create_augroup('ObsidianHL_' .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    buffer   = bufnr,
    group    = group,
    callback = function() apply(bufnr) end,
  })
  -- conceallevel/concealcursor are window-local; re-apply for splits
  vim.api.nvim_create_autocmd('BufWinEnter', {
    buffer   = bufnr,
    group    = group,
    callback = set_win_opts,
  })
  -- Re-apply highlight group defaults after a colorscheme swap
  vim.api.nvim_create_autocmd('ColorScheme', {
    group    = group,
    callback = setup_hl,
  })
end

return M
