" obsidian_links.vim — syntax rules for Obsidian [[wiki-links]]
" Sourced by ftplugin/markdown/obsidian.vim; also safe to :runtime manually.

" ── Match regions ────────────────────────────────────────────────────────────

" Full region: [[ … ]]
" keepend        — don't let the inner matches bleed past ]]
" concealends    — hide [[ and ]] if 'conceallevel' ≥ 2 (optional, harmless if not used)
syntax region ObsidianLink
      \ matchgroup=ObsidianLinkDelim
      \ start='\[\['
      \ end='\]\]'
      \ keepend
      \ contains=ObsidianLinkSep,ObsidianLinkAlias

" The pipe separator  [[target|alias]]
syntax match ObsidianLinkSep '|' contained

" Everything after the pipe is the display alias
syntax match ObsidianLinkAlias '\%(|\)\@<=[^\]]\+' contained

" ── Highlight links ──────────────────────────────────────────────────────────
" Tie into standard Vim groups so any colorscheme looks reasonable.
" Users can override these in their vimrc after the plugin loads.

highlight default link ObsidianLink        Underlined
highlight default link ObsidianLinkDelim   Comment
highlight default link ObsidianLinkSep     Comment
highlight default link ObsidianLinkAlias   Title
