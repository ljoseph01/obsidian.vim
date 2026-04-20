" ----------------------------------------------------------------------------
" Function: FindVaultRoot
"
" Finds the root of the current obisidian vault.
"
" Strategy:
"   - Search the current dir for a .obsidian dir
"   - Search parent dirs for a .obsidian dir
"
" Returns:
"   - A string  like 'path/to/dir'
"   - '' if not found
" ----------------------------------------------------------------------------
function! obsidian#FindVaultRoot()
    let l:dir = expand('%:p:h')
    while l:dir != fnamemodify(l:dir, ':h')
        if isdirectory(l:dir .. "/.obsidian")
            return l:dir
        endif
    let l:dir = fnamemodify(l:dir, ':h')
    endwhile
    return ''
endfunction

