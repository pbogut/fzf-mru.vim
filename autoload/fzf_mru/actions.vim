" =============================================================================
" File:          autoload/fzf_mru/mrufiles.vim
" Description:   Most Recently Used Files
" Author:        Pawel Bogut <github.com/pbogut>
" =============================================================================

function! fzf_mru#actions#params(params)
  let params = a:params
  if (len(params) && params[0] != '-')
    let params = '-q ' . shellescape(params)
  endif

  return params
endfunction

function! fzf_mru#actions#options() abort
  let options = '--prompt "MRU>" '
  if !empty(get(g:, 'fzf_mru_no_sort', 0))
    let options .= '--no-sort '
  endif
  return options
endfunction

function! s:p(...)
  let preview_window = get(g:, 'fzf_preview_window', '')
    if len(preview_window)
      return call('fzf#vim#with_preview', add(copy(a:000), preview_window))
    endif
  return {}
endfunction

function! fzf_mru#actions#mru(...) abort
  let params = fzf_mru#actions#params(get(a:, 001, ''))
  let options = extend(
        \   {
        \     'source': fzf_mru#mrufiles#source(),
        \     'options': fzf_mru#actions#options() . params,
        \   },
        \   get(a:, 002, {})
        \ )

  let extra = extend(copy(get(g:, 'fzf_layout', {'down': '~40%'})), options)

  call fzf#run(fzf#wrap('name', extend(extra, s:p()), 0))
endfunction
