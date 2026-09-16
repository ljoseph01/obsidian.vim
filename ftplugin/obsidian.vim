" Functions - only define once per session
if !exists('*ObsidianFollowLink')

    " ============================================================================
    " Obsidian-style Link Navigation
    " ----------------------------------------------------------------------------
    " Features:
    "   - Detect [[links]] under cursor
    "   - Parse:
    "       [[file]]
    "       [[file|alias]]
    "       [[file#heading]]
    "       [[file#heading|alias]]
    "       [[#heading]] (same file)
    "   - Resolve files:
    "       1. Local directory (relative to current file)
    "       2. Vault root (explicit paths)
    "       3. Global search (fallback → inputlist in Vim, vim.ui.select in Neovim)
    "   - Jump to headings inside files
    " ============================================================================


    " ----------------------------------------------------------------------------
    " FUNCTION: GetObsidianLink
    " ----------------------------------------------------------------------------
    function! s:GetObsidianLink()
        let line = getline('.')
        let col = col('.') - 1   " 0-based

        let start = 0
        while 1
            let m = matchstrpos(line, '\[\[[^]]\+\]\]', start)
            if m[1] == -1 | break | endif
            if col >= m[1] && col < m[2]
                return m[0]
            endif
            let start = m[2]
        endwhile
        return ''
    endfunction


    " ----------------------------------------------------------------------------
    " FUNCTION: ParseObsidianLink
    " ----------------------------------------------------------------------------
    function! s:ParseObsidianLink(link)
        let content = a:link[2:-3]
        let parts   = split(content, '|')
        let target  = parts[0]

        let result = {'file': '', 'heading': '', 'heading_level': 0}

        let idx = stridx(target, '#')
        if idx != -1
            let result.file          = target[:idx-1]
            let rest                 = target[idx:]
            let result.heading_level = len(matchstr(rest, '^#\+'))
            let result.heading       = substitute(rest, '^#\+', '', '')
        else
            let result.file = target
        endif

        return result
    endfunction


    " ----------------------------------------------------------------------------
    " FUNCTION: JumpToHeading
    " ----------------------------------------------------------------------------
    function! s:JumpToHeading(parsed)
        if a:parsed.heading ==# '' | return | endif
        let hashes  = repeat('#', a:parsed.heading_level)
        let text    = escape(a:parsed.heading, '.*[]\')
        call search('^' .. hashes .. '\s\+' .. text, 'w')
    endfunction


    " ----------------------------------------------------------------------------
    " FUNCTION: ResolveFile
    "
    " Takes a Callback funcref instead of returning a path, because the
    " multi-match picker (vim.ui.select in Neovim) may be async.
    " ----------------------------------------------------------------------------
    function! s:ResolveFile(file, vault, Callback) abort
        if a:file ==# ''
            call a:Callback(expand('%:p'))
            return
        endif

        let fname = a:file =~# '\.md$' ? a:file : a:file .. '.md'

        " 1. Local directory
        let local = expand('%:p:h') .. '/' .. fname
        if filereadable(local) | call a:Callback(local) | return | endif

        " 2. Vault root
        let rooted = a:vault .. '/' .. fname
        if filereadable(rooted) | call a:Callback(rooted) | return | endif

        " 3. Global search
        let matches = globpath(a:vault, '**/' .. fname, 0, 1)

        if len(matches) == 0 | return | endif
        if len(matches) == 1 | call a:Callback(matches[0]) | return | endif

        " Multiple matches — use vim.ui.select in Neovim so any picker plugin
        " (e.g. fzf-lua) is picked up automatically; fall back to inputlist in Vim.
        if has('nvim')
            call luaeval('require("obsidian.ui").pick(_A[1], _A[2], _A[3])',
                        \ [matches, fname, a:Callback])
        else
            let choices = ['Multiple matches for ' .. fname .. ':']
            for [i, m] in items(matches)
                call add(choices, (i + 1) .. '. '
                            \ .. substitute(m, '^' .. escape(a:vault, '\'), '', ''))
            endfor
            let idx = inputlist(choices)
            if idx > 0 && idx <= len(matches)
                call a:Callback(matches[idx - 1])
            endif
        endif
    endfunction


    " ----------------------------------------------------------------------------
    " FUNCTION: ObsidianFollowLink
    " ----------------------------------------------------------------------------

    " Pending navigation state; set before ResolveFile so the async callback
    " (vim.ui.select) can reach it without needing a closure.
    let s:_pending = {}

    function! s:OpenFile(file) abort
        execute s:_pending.method .. ' ' .. fnameescape(a:file)
        call s:JumpToHeading(s:_pending.parsed)
        let s:_pending = {}
    endfunction

    function! ObsidianFollowLink(edit_method) abort
        let vault = b:obsidian_vault_root
        let link  = s:GetObsidianLink()
        if link ==# '' | return | endif

        let method = a:edit_method ==# '' ? 'edit' : a:edit_method
        if index(['edit', 'split', 'vsplit', 'pedit', 'tabedit'], method) < 0
            echohl ErrorMsg
            echo 'ObsidianFollowLink: unknown edit method ' .. method
            echohl None
            return
        endif

        let parsed      = s:ParseObsidianLink(link)
        let s:_pending  = {'method': method, 'parsed': parsed}
        call s:ResolveFile(parsed.file, vault, function('s:OpenFile'))
    endfunction


    " ----------------------------------------------------------------------------
    " FUTURE IDEAS
    "
    " - Backlinks via :grep
    " - Completion for [[...]]
    " - Cache vault file list for speed
    " - Better heading normalization (lowercase, strip punctuation)
    " ----------------------------------------------------------------------------

endif


" Per-buffer setup — runs every time
let b:obsidian_vault_root = obsidian#FindVaultRoot()

" Mappings are buffer-local so they must be set for every buffer, not
" just the first one (which is why they live here, not inside the guard).
nnoremap <buffer><silent> gd                   :call ObsidianFollowLink('edit')<CR>
nnoremap <buffer><silent> <leader>gd           :call ObsidianFollowLink('pedit')<CR>
nnoremap <buffer><silent> <leader><leader>gd   :call ObsidianFollowLink('vsplit')<CR>
nnoremap <buffer><silent> <leader><leader><leader>gd :call ObsidianFollowLink('tabedit')<CR>

" Neovim: extmark-based highlights that work above treesitter
if has('nvim')
    lua require('obsidian.highlight').attach()
else
    " conceallevel/concealcursor are window-local; re-apply for splits
    setlocal conceallevel=2 concealcursor=
    execute 'augroup obsidian_conceal_win_' . bufnr('%')
        autocmd! BufWinEnter <buffer> setlocal conceallevel=2 concealcursor=
    augroup END
endif
