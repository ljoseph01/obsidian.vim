" obsidian_links.vim — syntax rules for Obsidian [[wiki-links]]
" Sourced by ftplugin/markdown/obsidian.vim; also safe to :runtime manually.

" ── Match regions ────────────────────────────────────────────────────────────

" Plain link: [[target]]
" concealends hides [[ and ]] when conceallevel >= 2.
syntax region ObsidianLink
      \ matchgroup=ObsidianLinkDelim
      \ start='\[\['
      \ end='\]\]'
      \ keepend
      \ concealends
      \ contains=ObsidianLinkSep,ObsidianLinkAlias

" The pipe separator  [[target|alias]]
syntax match ObsidianLinkSep '|' contained

" Everything after the pipe is the display alias
syntax match ObsidianLinkAlias '\%(|\)\@<=[^\]]\+' contained

" Aliased link: [[target|alias]]
" Must be defined AFTER ObsidianLink — Vim uses the last-defined item when
" multiple regions match at the same position (:help syn-priority rule 2).
" concealends hides the start ([[target|) and end (]]) when conceallevel >= 2,
" leaving only the alias text visible.
syntax region ObsidianLinkAliased
      \ matchgroup=ObsidianLinkDelim
      \ start='\[\[[^\]|]*|'
      \ end='\]\]'
      \ keepend
      \ concealends

" ── Highlight links ──────────────────────────────────────────────────────────
" Tie into standard Vim groups so any colorscheme looks reasonable.
" Users can override these in their vimrc after the plugin loads.

highlight default link ObsidianLink        Underlined
highlight default link ObsidianLinkAliased ObsidianLinkAlias
highlight default link ObsidianLinkDelim   Comment
highlight default link ObsidianLinkSep     Comment
highlight default link ObsidianLinkAlias   Title
