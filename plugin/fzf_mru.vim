" =============================================================================
" File:          plugin/fzf_mru.vim
" Description:   CtrlP Most Recently Used Files source for FZF
" Author:        Pawel Bogut <github.com/pbogut>
" =============================================================================

if exists('g:fzf_mru_loaded')
  finish
endif
let g:fzf_mru_loaded = 1

call fzf_mru#mrufiles#init()

if exists(':FZFMru') != 2
  command! -nargs=* FZFMru call fzf_mru#actions#mru(<q-args>)
endif
if exists(':FZFFreshMru') != 2
  command! -nargs=* FZFFreshMru call fzf_mru#mrufiles#refresh() <bar> call fzf_mru#actions#mru(<q-args>)
endif
