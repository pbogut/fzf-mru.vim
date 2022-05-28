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

  call fzf#run(fzf#wrap('name', extra, 0))
endfunction

if v:version >= 704
  function! s:function(name)
    return function(a:name)
  endfunction
else
  function! s:function(name)
    " By Ingo Karkat
    return function(substitute(a:name, '^s:', matchstr(expand('<sfile>'), '<SNR>\d\+_\zefunction$'), ''))
  endfunction
endif

function! s:jump(t, w)
  execute a:t.'tabnext'
  execute a:w.'wincmd w'
endfunction

function! s:format_win(tab, win, buf)
  let modified = getbufvar(a:buf, '&modified')
  let name = bufname(a:buf)
  let name = empty(name) ? '[No Name]' : name
  let active = tabpagewinnr(a:tab) == a:win
  return (active? '> ' : '  ') . name . (modified? ' [+]' : '')
endfunction

function! s:windows_sink(line)
  let list = matchlist(a:line, '^ *\([0-9]\+\) *\([0-9]\+\)')
  call s:jump(list[1], list[2])
endfunction

function! fzf_mru#actions#windows()
  let lines = []
  let mru = fzf_mru#mrufiles#source()
  let filteredBufs = []
  let filteredBufsIndex = []
  let tabs = []
  let buffers = {}
  for t in range(1, tabpagenr('$'))
   let buffers[t] = tabpagebuflist(t)
   for w in range(1, len(buffers[t]))
     let index = index(mru, bufname(buffers[t][w-1]))
     if index >= 0
         call add(filteredBufs, mru[index])
         call add(filteredBufsIndex, buffers[t][w-1])
         call add(tabs, t)
     endif
   endfor
  endfor
  for item in range(1, len(mru))
   let i = index(filteredBufs, mru[item-1])
   if i < 0
    continue
   endif
   let t = tabs[i]
   let w = index(buffers[t], filteredBufsIndex[i]) + 1
   call add(lines,
     \ printf('%s %s  %s',
         \ printf('%3d', tabs[i]),
         \ printf('%3d', w),
         \ s:format_win(tabs[i], w, filteredBufsIndex[i])))
  endfor
  call fzf#run(fzf#wrap("Recent Windows", {
  \ 'source':  extend(['Tab Win    Name'], lines),
  \ 'sink':    s:function('s:windows_sink'),
  \ 'options': '+m --ansi --tiebreak=begin --header-lines=1'}))
endfunction
