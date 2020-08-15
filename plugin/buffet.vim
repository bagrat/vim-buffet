" vim-buffet  - IDE-like tabs 
" Author:       Bagrat Aznauryan <contact@bagrat.io>
" Url:          https://github.com/bagrat/vim-buffet
" License:      MIT
" ===========================================================================

if exists("g:buffet_loaded")
  finish
endif

let g:buffet_loaded = 1

let g:buffet_always_show_tabline = get(g:, "buffet_always_show_tabline", 1)
let g:buffet_show_index = get(g:, "buffet_show_index", 0)
let g:buffet_max_plug = get(g:, "buffet_max_plug", 10)
let g:buffet_hidden_buffers = get(g:, 'buffet_hidden_buffers', ['terminal', 'quickfix'])

if get(g:, "buffet_use_devicons", 1)
  let g:buffet_use_devicons = exists("*WebDevIconsGetFileTypeSymbol") ? 1 : 0
else
  let g:buffet_use_devicons = 0
endif

if get(g:, "buffet_powerline_separators", 0)
  let g:buffet_powerline_separators = 1
  let g:buffet_noseparator = "\ue0b0"
  let g:buffet_separator = "\ue0b1"
else
  let g:buffet_powerline_separators = 0
  let g:buffet_noseparator = get(g:, "buffet_noseparator", " ")
  let g:buffet_separator = get(g:, "buffet_separator", "|")
endif

let g:buffet_modified_icon = get(g:, 'buffet_modified_icon', '+')
let g:buffet_left_trunc_icon = get(g:, 'buffet_left_trunc_icon', '<')
let g:buffet_right_trunc_icon = get(g:, 'buffet_right_trunc_icon', '>')
let g:buffet_new_buffer_name = get(g:, 'buffet_new_buffer_name', '*')
let g:buffet_tab_icon = get(g:, 'buffet_tab_icon', '#')

augroup buffet_show_tabline
  autocmd!
  autocmd VimEnter,BufAdd,TabEnter * set showtabline=2
augroup END

if has("gui") || has("termguicolors")
  if !get(g:, "buffet_use_gui_tablne", 0)
    set guioptions-=e
  endif
endif

let g:buffet_prefix = "Buffet"
let g:buffet_has_separator = {
      \ "Tab": {
      \   "Tab": g:buffet_separator,
      \   "LeftTrunc": g:buffet_separator,
      \   "End" : g:buffet_separator,
      \ },
      \ "LeftTrunc": {
      \   "Buffer": g:buffet_separator,
      \   "CurrentBuffer": g:buffet_separator,
      \   "ActiveBuffer": g:buffet_separator,
      \   "ModBuffer": g:buffet_separator,
      \ },
      \ "RightTrunc": {
      \   "Tab": g:buffet_separator,
      \   "End": g:buffet_separator,
      \ }}

let g:buffet_buffer_types = [
      \ "Buffer",
      \ "ActiveBuffer",
      \ "CurrentBuffer",
      \ "ModBuffer",
      \ "ModActiveBuffer",
      \ "ModCurrentBuffer"]

for s:type in g:buffet_buffer_types
  let g:buffet_has_separator["Tab"][s:type] = g:buffet_separator
  let g:buffet_has_separator[s:type] = {
        \ "RightTrunc": g:buffet_separator,
        \ "Tab": g:buffet_separator,
        \ "End": g:buffet_separator}

  for s:t in g:buffet_buffer_types
    let g:buffet_has_separator[s:type][s:t] = g:buffet_separator
  endfor
endfor

augroup buffet_set_colors
  autocmd!
  autocmd ColorScheme * call buffet#colors#init_color_highlights()
augroup end

" Set solors also at the startup
call buffet#colors#init_color_highlights()

if has("nvim")
  function! SwitchToBuffer(buffer_id, clicks, btn, flags)
    exec "silent buffer " . a:buffer_id
  endfunction
endif

function! buffet#bwipe_nerdtree_filter(bang, buffer)
  let is_in_nt = 0
  if exists("t:NERDTreeBufName")
    let ntwinnr = bufwinnr(t:NERDTreeBufName)

    if ntwinnr == winnr()
      let is_in_nt = 1
    endif
  endif

  if is_in_nt
    return 1
  endif
endfunction

let g:buffet_bwipe_filters = ["buffet#bwipe_nerdtree_filter"]

for s:n in range(1, g:buffet_max_plug)
  execute printf("noremap <silent> <Plug>BuffetSwitch(%d) :call buffet#bswitch(%d)<cr>", s:n, s:n)
endfor

command! -bang -complete=buffer -nargs=? Bw call buffet#bwipe(<q-bang>, <q-args>)
command! -bang -complete=buffer -nargs=? Bonly call buffet#bonly(<q-bang>, <q-args>)

set tabline=%!buffet#render()
