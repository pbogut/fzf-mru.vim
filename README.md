# FZF :heart: MRU

[![Project Status: Active - The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)

Vim plugin that allows using awesome [CtrlP](https://github.com/kien/ctrlp.vim)
MRU plugin with even more amazing [fzf](https://github.com/junegunn/fzf)

I love **FZF** fuzzy search algorithm and **CtrlP** Mru tracking - I'm using it
often to jump between two files (yes, I'm aware of `<c-^>`). The way how
**fzf-vim's** `:History` works was not the best solution for me that's why I
decided to create this plugin. It requires **fzf**.

## Instalation

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'junegunn/fzf'

Plug 'pbogut/fzf-mru.vim'
```

Using [Vundle](https://github.com/VundleVim/Vundle.vim):

```vim
Plugin 'junegunn/fzf'

Plugin 'pbogut/fzf-mru.vim'
```

## Basic Usage
- You can run `:FZFMru`, `:FZFMru [search-query]` or `:FZFMru [fzf-command-options]`.
- For example: `:FZFMru --prompt "Sup? " -q "notmuch"` or `:FZFMru readme`
- You can also map it to a shortcut with `map <leader>p :FZFMru<cr>`.
- Set `let g:fzf_mru_relative = 1` to only list files within current directory.

## Todo
- [x] ~~Move CtrlP MRU functionality to the plugin itself~~
- [x] ~~Make `fzf.vim` optional dependency~~
- [ ] Add Vim help

## Credits

99% of MRU engine has been taken from [CtrlP](https://github.com/kien/ctrlp.vim).

## Contribution

Always welcome.

## License

MIT License;
The software is provided "as is", without warranty of any kind.
