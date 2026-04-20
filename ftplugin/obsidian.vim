" Functions and mappings - only define once
if !exists('*ObsidianFollowLink')

    " ============================================================================
    " Obsidian-style Link Navigation for Vim (legacy Vimscript)
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
    "       3. Global search (fallback)
    "   - Jump to headings inside files
    "
    " Requirements:
    "   - Set g:obsidian_vault to your vault path
    "
    " Optional improvements:
    "   - fzf integration for multiple matches
    "   - caching for performance
    "
    " ============================================================================


    " ----------------------------------------------------------------------------
    " FUNCTION: GetObsidianLink
    "
    " Finds a [[link]] under the cursor on the current line.
    "
    " Strategy:
    "   - Scan the line for all [[...]] patterns
    "   - Return the one that contains the cursor
    "
    " Returns:
    "   - string like '[[file#heading|alias]]'
    "   - or '' if none found
    " ----------------------------------------------------------------------------
    function! s:GetObsidianLink()
        let line = getline('.')
        let col = col('.') - 1   " convert to 0-based index

        let start = 0

        while 1
            " matchstrpos returns:
            " [match, start_index, end_index]
            let m = matchstrpos(line, '\[\[[^]]\+\]\]', start)

            if m[1] == -1
                break
            endif

            let match_start = m[1]
            let match_end   = m[2]

            " Check if cursor is inside this match
            if col >= match_start && col < match_end
                return m[0]
            endif

            let start = match_end
        endwhile

        return ''
    endfunction


    " ----------------------------------------------------------------------------
    " FUNCTION: ParseObsidianLink
    "
    " Parses a link string into components.
    "
    " Input:
    "   [[file#heading|alias]]
    "
    " Output dict:
    "   {
    "     'file': 'file',
    "     'heading': 'heading'
    "   }
    "
    " Notes:
    "   - alias is ignored (display-only in Obsidian)
    " ----------------------------------------------------------------------------
    function! s:ParseObsidianLink(link)
        " Strip [[ and ]]
        let content = a:link[2:-3]

        " Split alias (file#heading | alias)
        let parts = split(content, '|')
        let target = parts[0]

        let result = {
                    \ 'file': '',
                    \ 'heading': ''
                    \ }

        " Split heading
        if target =~ '#'
            let sub = split(target, '#', 1)
            let result.file = sub[0]
            let result.heading = sub[1]
        else
            let result.file = target
        endif

        return result
    endfunction


    " ----------------------------------------------------------------------------
    " FUNCTION: ResolveFile
    "
    " Resolves a filename to a full path.
    "
    " Strategy:
    "   1. If empty → current file
    "   2. Local directory (same folder as current file)
    "   3. Vault root (for explicit paths)
    "   4. Global search (fallback)
    "
    " Returns:
    "   - full path or ''
    " ----------------------------------------------------------------------------
    function! s:ResolveFile(file, vault)
        " Same-file reference (e.g. [[#heading]])
        if a:file == ''
            return expand('%:p')
        endif

        let fname = a:file

        " Ensure .md extension
        if fname !~ '\.md$'
            let fname .= '.md'
        endif

        " --- 1. Local directory ---
        let local = expand('%:p:h') . '/' . fname
        if filereadable(local)
            return local
        endif

        " --- 2. Vault-root relative ---
        let rooted = a:vault . '/' . fname
        if filereadable(rooted)
            return rooted
        endif

        " --- 3. Global search ---
        let matches = globpath(a:vault, '**/' . fname, 0, 1)

        if len(matches) == 0
            return ''
        endif

        " If multiple matches exist, we just take the first for now.
        " You can later plug in fzf here.
        return matches[0]
    endfunction


    " ----------------------------------------------------------------------------
    " FUNCTION: JumpToHeading
    "
    " Jumps to a markdown heading in the current buffer.
    "
    " Matches:
    "   # Heading
    "   ## Heading
    "   etc.
    "
    " Notes:
    "   - Case-insensitive
    "   - Basic matching (can be improved with normalization)
    " ----------------------------------------------------------------------------
    function! s:JumpToHeading(heading)
        if a:heading == ''
            return
        endif

        " Escape regex characters
        let pattern = '^#\+\s*' . escape(a:heading, '.*[]\')

        " 'w' = wrap around file
        call search(pattern, 'w')
    endfunction


    " ----------------------------------------------------------------------------
    " FUNCTION: ObsidianFollowLink
    "
    " Main entry point.
    "
    " Flow:
    "   1. Get link under cursor
    "   2. Parse it
    "   3. Resolve file
    "   4. Open file
    "   5. Jump to heading (if any)
    " ----------------------------------------------------------------------------
    function! ObsidianFollowLink(edit_method)
        let vault = b:obsidian_vault_root
        let link = s:GetObsidianLink()

        if link == ''
            " echo "No Obsidian link under cursor"
            return
        endif

        let parsed = s:ParseObsidianLink(link)
        let file = s:ResolveFile(parsed.file, vault)

        if file == ''
            " echo "File not found: " . parsed.file
            return
        endif

        let method = a:edit_method ==# '' ? 'edit' : a:edit_method
        if index([
                    \ 'edit',
                    \ 'split',
                    \ 'vsplit',
                    \ 'pedit',
                    \ 'tabedit'
                    \ ], method) < 0
            echohl ErrorMsg | echo "ObsidianFollowLink: Unkwown edit method " .. method
            return
        endif
        execute method .. ' ' .. fnameescape(file)

        call s:JumpToHeading(parsed.heading)
    endfunction


    " ----------------------------------------------------------------------------
    " MAPPINGS
    "
    " Change this if you don't want to override gf
    " ----------------------------------------------------------------------------

    nnoremap <silent> gd :call ObsidianFollowLink('edit')<CR>
    nnoremap <silent> <leader>gd :call ObsidianFollowLink('pedit')<CR>
    nnoremap <silent> <leader><leader>gd :call ObsidianFollowLink('vsplit')<CR>
    nnoremap <silent> <leader><leader><leader>gd :call ObsidianFollowLink('tabedit')<CR>

    " Alternative:
    " nnoremap <leader>of :call ObsidianFollowLink()<CR>


    " ----------------------------------------------------------------------------
    " FUTURE IDEAS (for when you come back later)
    "
    " - FZF integration for multiple matches
    " - Backlinks via :grep
    " - Completion for [[...]]
    " - Cache vault file list for speed
    " - Better heading normalization (lowercase, strip punctuation)
    "
    " ----------------------------------------------------------------------------

endif

" Per-buffer setup - runs every time
let b:obsidian_vault_root = obsidian#FindVaultRoot()
