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

function! s:fzf_mru_source()
  " remove current file from the list
  return filter(copy(fzf_mru#mrufiles#list()), 'v:val != expand("%")')
endfunction

" prepare params
function! s:params(params)
  let params = join(a:params, ' ')
  if (len(params) && params[0] != '-')
    let params = '-q ' . shellescape(params)
  endif

  return params
endfunction

function! s:fzf_options() abort
  let l:options = '--prompt "MRU>" '
  if !empty(get(g:, 'fzf_mru_no_sort', 0))
    let l:options .= '--no-sort '
  endif
  return l:options
endfunction

function! s:fzf_mru(...) abort
  let options = {
        \   'source': s:fzf_mru_source(),
        \   'options': s:fzf_options() . s:params(a:000),
        \ }
  let extra = extend(copy(get(g:, 'fzf_layout', {'down': '~40%'})), options)

  call fzf#run(fzf#wrap('name', extra, 0))
endfunction

command! -nargs=* FZFMru call s:fzf_mru(<q-args>)
command! -nargs=* FZFFreshMru call fzf_mru#mrufiles#refresh() <bar> call s:fzf_mru(<q-args>)
