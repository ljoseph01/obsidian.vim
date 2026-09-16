augroup obsidian_ftdetect
    autocmd!
    autocmd BufRead,BufNewFile *.md,*.markdown,*.mdown,*.mkd,*.mkdn,*.mdwn
                \ call s:DetectObsidian()
augroup END

function! s:DetectObsidian() abort
    if obsidian#FindVaultRoot() !=# ''
        set filetype=markdown.obsidian
    endif
endfunction
