" =============================================================================
" File:          autoload/fzf_mru/mrufiles.vim
" Description:   Most Recently Used Files
" Author:        Pawel Bogut <github.com/pbogut>
" Credits:       Based on CtrlP by Kien Nguyen <github.com/kien>
" =============================================================================

" Static variables {{{1
let [s:mrbs, s:mrufs] = [[], []]

fu! fzf_mru#mrufiles#opts()
  let [pref, opts] = ['g:fzf_mru_', {
        \ 'max': ['s:max', 250],
        \ 'include': ['s:in', ''],
        \ 'exclude': ['s:ex', ''],
        \ 'case_sensitive': ['s:cseno', 1],
        \ 'relative': ['s:re', 0],
        \ 'store_relative_dirs': ['s:stre', []],
        \ 'save_on_update': ['s:soup', 1],
        \ 'exclude_current_file': ['s:excur', 1],
        \ }]
  for [ke, va] in items(opts)
    let [{va[0]}, {pref.ke}] = [pref.ke, exists(pref.ke) ? {pref.ke} : va[1]]
  endfo
endf
cal fzf_mru#mrufiles#opts()
" Utilities {{{1
fu! s:excl(fn)
  retu !empty({s:ex}) && a:fn =~# {s:ex}
endf

fu! s:mergelists()
  let diskmrufs = fzf_mru#utils#readfile(fzf_mru#mrufiles#cachefile())
  cal filter(diskmrufs, 'index(s:mrufs, v:val) < 0')
  let mrufs = s:mrufs + diskmrufs
  retu s:chop(mrufs)
endf

fu! s:chop(mrufs)
  if len(a:mrufs) > {s:max} | cal remove(a:mrufs, {s:max}, -1) | en
  retu a:mrufs
endf

fu! s:reformat(mrufs, ...)
  let cwd = getcwd()
  let cwd .= cwd !~ '[\/]$' ? fzf_mru#utils#lash() : ''
  if {s:re}
    let cwd = exists('+ssl') ? tr(cwd, '/', '\') : cwd
    cal filter(a:mrufs, '!stridx(v:val, cwd)')
  en
  if a:0 && a:1 == 'raw' | retu a:mrufs | en
  let idx = strlen(cwd)
  if exists('+ssl') && &ssl
    let cwd = tr(cwd, '\', '/')
    cal map(a:mrufs, 'tr(v:val, "\\", "/")')
  en
  retu map(a:mrufs, '!stridx(v:val, cwd) ? strpart(v:val, idx) : v:val')
endf

fu! s:record(bufnr)
  if s:locked | retu | en
  let bufnr = a:bufnr + 0
  let bufname = bufname(bufnr)
  if bufnr > 0 && !empty(bufname)
    cal filter(s:mrbs, 'v:val != bufnr')
    cal insert(s:mrbs, bufnr)
    cal s:addtomrufs(bufname)
  en
endf

fu! s:addtomrufs(fname)
  let fn = fnamemodify(a:fname, ':p')
  for rdir in {s:stre}
    if getcwd() =~ rdir
      let fn = fnamemodify(a:fname, ':.')
      break
    endif
  endfor
  let fn = exists('+ssl') ? tr(fn, '/', '\') : fn
  if ( !empty({s:in}) && fn !~# {s:in} ) || ( !empty({s:ex}) && fn =~# {s:ex} )
        \ || !empty(getbufvar('^'.fn.'$', '&bt')) || !filereadable(fn) | retu
  en
  let idx = index(s:mrufs, fn, 0, !{s:cseno})
  if idx
    cal filter(s:mrufs, 'v:val !='.( {s:cseno} ? '#' : '?' ).' fn')
    cal insert(s:mrufs, fn)
    if {s:soup} && idx < 0
      cal s:savetofile(s:mergelists())
    en
  en
endf

fu! s:savetofile(mrufs)
  cal fzf_mru#utils#writecache(a:mrufs, s:cadir, s:cafile)
endf
" Public {{{1
fu! fzf_mru#mrufiles#refresh(...)
  let mrufs = s:mergelists()
  cal filter(s:mrufs, '!empty(fzf_mru#utils#glob(v:val, 1)) && !s:excl(v:val)')
  cal filter(mrufs, '!empty(fzf_mru#utils#glob(v:val, 1)) && !s:excl(v:val)')
  if exists('+ssl')
    cal map(mrufs, 'tr(v:val, "/", "\\")')
    cal map(s:mrufs, 'tr(v:val, "/", "\\")')
    let cond = 'count(mrufs, v:val, !{s:cseno}) == 1'
    cal filter(mrufs, cond)
    cal filter(s:mrufs, cond)
  en
  cal s:savetofile(mrufs)
  retu a:0 && a:1 == 'raw' ? [] : s:reformat(mrufs)
endf

fu! fzf_mru#mrufiles#remove(files)
  let mrufs = []
  if a:files != []
    let mrufs = s:mergelists()
    let cond = 'index(a:files, v:val, 0, !{s:cseno}) < 0'
    cal filter(mrufs, cond)
    cal filter(s:mrufs, cond)
  en
  cal s:savetofile(mrufs)
  retu s:reformat(mrufs)
endf

fu! fzf_mru#mrufiles#add(fn)
  if !empty(a:fn)
    cal s:addtomrufs(a:fn)
  en
endf

fu! fzf_mru#mrufiles#raw_list()
  return s:mergelists()
endf

fu! fzf_mru#mrufiles#list(...)
  retu a:0 ? a:1 == 'raw' ? s:reformat(s:mergelists(), a:1) : 0
        \ : s:reformat(s:mergelists())
endf

fu! fzf_mru#mrufiles#bufs()
  retu s:mrbs
endf

fu! fzf_mru#mrufiles#tgrel()
  let {s:re} = !{s:re}
endf

fu! fzf_mru#mrufiles#cachefile()
  if !exists('s:cadir') || !exists('s:cafile')
    let s:cadir = fzf_mru#utils#cachedir()
    let s:cafile = s:cadir.fzf_mru#utils#lash().'cache.txt'
  en
  retu s:cafile
endf

function! fzf_mru#mrufiles#source()
  let source = copy(fzf_mru#mrufiles#list())
  if !empty({s:excur})
    " remove current file from the list
    let source = filter(source, 'v:val != expand("%")')
  endif
  return source
endfunction

fu! fzf_mru#mrufiles#init()
  if !has('autocmd') | retu | en
  let s:locked = 0
  aug pb_fzf_mru
    au!
    au BufAdd,BufEnter,BufLeave,BufWritePost * cal s:record(expand('<abuf>', 1))
    au QuickFixCmdPre  *vimgrep* let s:locked = 1
    au QuickFixCmdPost *vimgrep* let s:locked = 0
    au VimLeavePre * cal s:savetofile(s:mergelists())
  aug END
endf
"}}}

" vim:fen:fdm=marker:fmr={{{,}}}:fdl=0:fdc=1:ts=2:sw=2:sts=2
