# obsidian.vim

A Vim plugin for navigating Obsidian vaults using legacy Vimscript. Adds `[[wiki-link]]` navigation and syntax highlighting to markdown files inside an Obsidian vault, without replacing any built-in markdown functionality.

## Installation

```sh
git clone https://github.com/ljoseph01/obsidian.vim ~/.vim/pack/ljoseph01/start/obsidian
```

No further setup required. The plugin auto-detects Obsidian vaults by searching parent directories for a `.obsidian/` folder.

## Requirements

- Vim (legacy Vimscript, no Neovim-specific features used)
- Obsidian vault with a `.obsidian/` directory at its root

## Symlink setup

If you symlink project `notes/` directories into your vault, the symlinks must point **from** the project **into** the vault — not the other way around:

```sh
# Correct: project points into vault
ln -s ~/vault/projects/myproject ~/projects/myproject/notes

# Wrong: vault points into project (plugin can't find vault root)
# ln -s ~/projects/myproject/notes ~/vault/projects/myproject
```

This ensures that resolving symlinks always produces a path inside the vault tree, where `.obsidian/` is discoverable.

## Features

### Filetype detection

Files inside a vault are automatically set to `ft=markdown.obsidian`, which layers Obsidian-specific behaviour on top of all standard markdown functionality — syntax highlighting, folding, formatting options, etc. are all preserved.

### `[[wiki-link]]` navigation

Supports the full Obsidian link syntax:

| Format | Description |
|---|---|
| `[[file]]` | Link to a file |
| `[[file\|alias]]` | Link with display alias |
| `[[file#heading]]` | Link to a heading |
| `[[file#heading\|alias]]` | Link to a heading with alias |
| `[[#heading]]` | Link to a heading in the current file |

File resolution follows Obsidian's own logic:

1. Same directory as the current file
2. Vault-root relative path
3. Global search across the entire vault (`**/filename.md`)

### Keymaps

| Key | Action |
|---|---|
| `gd` | Follow link in current window |
| `<leader>gd` | Follow link in preview window |
| `<leader><leader>gd` | Follow link in vertical split |
| `<leader><leader><leader>gd` | Follow link in new tab |

### Syntax highlighting

`[[wiki-links]]` are highlighted using standard Vim groups, so they work with any colorscheme:

| Element | Default group |
|---|---|
| `[[` and `]]` delimiters | `Comment` |
| Link target | `Underlined` |
| `\|` separator | `Comment` |
| Alias text | `Title` |

Override any of these in your `vimrc` after the plugin loads:

```vim
highlight link ObsidianLinkAlias Statement
```

## Project structure

```
autoload/
  obsidian.vim          " Shared functions (vault root detection)
ftplugin/
  obsidian.vim          " Navigation functions and keymaps
syntax/
  obsidian.vim          " [[wiki-link]] syntax rules
after/
  ftplugin/
    markdown.vim        " Filetype detection — sets ft=markdown.obsidian
```
