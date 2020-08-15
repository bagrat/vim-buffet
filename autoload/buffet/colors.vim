function! buffet#colors#init_color_highlights()
  " TODO: try to match user's colorscheme
  " Issue: https://github.com/bagrat/vim-buffet/issues/5
  " if get(g:, "buffet_match_color_scheme", 1)

  hi! BuffetCurrentBuffer cterm=NONE ctermbg=2 ctermfg=8 guibg=#00FF00 guifg=#000000
  hi! BuffetActiveBuffer cterm=NONE ctermbg=10 ctermfg=2 guibg=#999999 guifg=#00FF00
  hi! BuffetBuffer cterm=NONE ctermbg=10 ctermfg=8 guibg=#999999 guifg=#000000

  hi! link BuffetModCurrentBuffer BuffetCurrentBuffer
  hi! link BuffetModActiveBuffer BuffetActiveBuffer
  hi! link BuffetModBuffer BuffetBuffer

  hi! BuffetTrunc cterm=bold ctermbg=11 ctermfg=8 guibg=#999999 guifg=#000000
  hi! BuffetTab cterm=NONE ctermbg=4 ctermfg=8 guibg=#0000FF guifg=#000000

  hi! link BuffetLeftTrunc BuffetTrunc
  hi! link BuffetRightTrunc BuffetTrunc
  hi! link BuffetEnd BuffetBuffer

  if exists("*g:BuffetSetCustomColors")
    call g:BuffetSetCustomColors()
  endif

  for left in keys(g:buffet_has_separator)
    for right in keys(g:buffet_has_separator[left])
      let vim_mode = "cterm"
      if has("gui") || has("termguicolors")
        let vim_mode = "gui"
      endif

      let left_hi = g:buffet_prefix . left
      let right_hi = g:buffet_prefix . right
      let left_bg = s:GetHiAttr(left_hi, 'bg')
      let right_bg = s:GetHiAttr(right_hi, 'bg')

      if left_bg == ""
        let left_bg = "NONE"
      endif

      if right_bg == ""
        let right_bg = "NONE"
      endif

      let sep_hi = g:buffet_prefix . left . right
      if left_bg != right_bg
        let g:buffet_has_separator[left][right] = g:buffet_noseparator

        call s:SetHi(sep_hi, left_bg, right_bg)
      else
        let g:buffet_has_separator[left][right] = g:buffet_separator

        call s:LinkHi(sep_hi, left_hi)
      endif
    endfor
  endfor
endfunction

function! s:GetHiAttr(name, attr)
  let vim_mode = "cterm"
  let attr_suffix = ""
  if has("gui") || has('termguicolors')
    let vim_mode = "gui"
    let attr_suffix = "#"
  endif

  let value = synIDattr(synIDtrans(hlID(a:name)), a:attr . attr_suffix, vim_mode)

  return value
endfunction

function! s:SetHi(name, fg, bg)
  let vim_mode = "cterm"
  if has("gui") || has("termguicolors")
    let vim_mode = "gui"
  endif

  let spec = ""
  if a:fg != ""
    let fg_spec = vim_mode . "fg=" . a:fg
    let spec = fg_spec
  endif

  if a:bg != ""
    let bg_spec = vim_mode . "bg=" . a:bg

    if spec != ""
      let bg_spec = " " . bg_spec
    endif

    let spec = spec . bg_spec
  endif

  if spec != ""
    exec "silent hi! " . a:name . " " . spec
  endif
endfunction

function! s:LinkHi(name, target)
  exec "silent hi! link " . a:name . " " . a:target
endfunction
