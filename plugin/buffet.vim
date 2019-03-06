set showtabline=2
set tabline=%!buffet#render()

let g:buffet_prefix = "Buffet"
let g:buffet_has_separator = {
            \     "Tab": {
            \         "Tab": 1,
            \         "LeftTrunc": 1,
            \         "Buffer": 1,
            \         "CurrentBuffer": 1,
            \         "ActiveBuffer": 1,
            \         "End" : 1,
            \     },
            \     "LeftTrunc": {
            \         "Buffer": 1,
            \         "CurrentBuffer": 1,
            \         "ActiveBuffer": 1,
            \     },
            \     "RightTrunc": {
            \         "Tab": 1,
            \         "End": 1,
            \     },
            \     "Buffer": {
            \         "Buffer": 1,
            \         "ActiveBuffer": 1,
            \         "CurrentBuffer": 1,
            \         "RightTrunc": 1,
            \         "Tab": 1,
            \         "End": 1,
            \     },
            \     "ActiveBuffer": {
            \         "Buffer": 1,
            \         "ActiveBuffer": 1,
            \         "CurrentBuffer": 1,
            \         "RightTrunc": 1,
            \         "Tab": 1,
            \         "End": 1,
            \     },
            \     "CurrentBuffer": {
            \         "Buffer": 1,
            \         "ActiveBuffer": 1,
            \         "RightTrunc": 1,
            \         "Tab": 1,
            \         "End": 1,
            \     },
            \     "End": {
            \         "End": 0,
            \     },
            \ }

function! s:SetColors()
    hi link BuffetActiveBuffer Cursor
    hi link BuffetCurrentBuffer Search
    hi link BuffetBuffer NonText
    hi link BuffetTab StatusLineTerm
    hi link BuffetEnd TablineFill
    hi link BuffetLeftTrunc ToolbarButton
    hi link BuffetRightTrunc ToolbarButton

    if exists("*g:BuffetSetCustomColors")
        call g:BuffetSetCustomColors()
    endif

    for left in keys(g:buffet_has_separator)
        for right in keys(g:buffet_has_separator[left])
            let vim_mode = "cterm"
            let attr_suffix = ""
            if has("gui")
                let vim_mode = "gui"
                let attr_suffix = "#"
            endif

            let left_bg = synIDattr(synIDtrans(hlID(g:buffet_prefix . left)), 'bg' . attr_suffix, vim_mode)
            let right_bg = synIDattr(synIDtrans(hlID(g:buffet_prefix . right)), 'bg' . attr_suffix, vim_mode)

            if left_bg != right_bg
                let g:buffet_has_separator[left][right] = 0
            endif
        endfor
    endfor
endfunction

augroup buffet_set_colors
    autocmd!
    autocmd ColorScheme * call s:SetColors()
augroup end

" Set solors also at the startup
call s:SetColors()
