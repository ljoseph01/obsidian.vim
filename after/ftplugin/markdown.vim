if &ft =~# 'obsidian'
    " echo "Already an obsidian filetype"
    finish
endif
" echo "Checking if an obsidian filetype"
if obsidian#FindVaultRoot() !=# ""
    " echo "Is obsidian, setting ft"
    set ft=markdown.obsidian
endif
