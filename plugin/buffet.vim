if exists("g:buffet_loaded")
    finish
endif

let g:buffet_loaded = 1

if get(g:, "buffet_always_show_tabline", 1)
    set showtabline=2
endif

" TODO: https://github.com/bagrat/vim-buffet/issues/6

let g:buffet_powerline_separators = 1
if get(g:, "buffet_powerline_separators", 0)
    let g:buffet_powerline_separators = 1
    let g:buffet_noseparator = "\ue0b0"
    let g:buffet_separator = "\ue0b1"
else
    let g:buffet_powerline_separators = 0
    let g:buffet_noseparator = get(g:, "buffet_noseparator", " ")
    let g:buffet_separator = get(g:, "buffet_separator", "|")
endif

" let g:buffet_use_devicons = 0
if get(g:, "buffet_use_devicons", 1)
    if !exists("*WebDevIconsGetFileTypeSymbol")
        let g:buffet_use_devicons = 0
    else
        let g:buffet_use_devicons = 1
    endif
else
    let g:buffet_use_devicons = 0
endif

if !exists("g:buffet_modified_icon")
    let g:buffet_modified_icon = "+"
endif

if !exists("g:buffet_left_trunc_icon")
    let g:buffet_left_trunc_icon = "<"
endif

if !exists("g:buffet_right_trunc_icon")
    let g:buffet_right_trunc_icon = ">"
endif

if !exists("g:buffet_tab_icon")
    let g:buffet_tab_icon = "#"
endif

let g:buffet_prefix = "Buffet"
let g:buffet_has_separator = {
            \     "Tab": {
            \         "Tab": g:buffet_separator,
            \         "LeftTrunc": g:buffet_separator,
            \         "Buffer": g:buffet_separator,
            \         "CurrentBuffer": g:buffet_separator,
            \         "ActiveBuffer": g:buffet_separator,
            \         "End" : g:buffet_separator,
            \     },
            \     "LeftTrunc": {
            \         "Buffer": g:buffet_separator,
            \         "CurrentBuffer": g:buffet_separator,
            \         "ActiveBuffer": g:buffet_separator,
            \     },
            \     "RightTrunc": {
            \         "Tab": g:buffet_separator,
            \         "End": g:buffet_separator,
            \     },
            \     "Buffer": {
            \         "Buffer": g:buffet_separator,
            \         "ActiveBuffer": g:buffet_separator,
            \         "CurrentBuffer": g:buffet_separator,
            \         "RightTrunc": g:buffet_separator,
            \         "Tab": g:buffet_separator,
            \         "End": g:buffet_separator,
            \     },
            \     "ActiveBuffer": {
            \         "Buffer": g:buffet_separator,
            \         "ActiveBuffer": g:buffet_separator,
            \         "CurrentBuffer": g:buffet_separator,
            \         "RightTrunc": g:buffet_separator,
            \         "Tab": g:buffet_separator,
            \         "End": g:buffet_separator,
            \     },
            \     "CurrentBuffer": {
            \         "Buffer": g:buffet_separator,
            \         "ActiveBuffer": g:buffet_separator,
            \         "RightTrunc": g:buffet_separator,
            \         "Tab": g:buffet_separator,
            \         "End": g:buffet_separator,
            \     },
            \     "End": {
            \         "End": g:buffet_noseparator,
            \     },
            \ }

function! s:GetHiAttr(name, attr)
    let vim_mode = "cterm"
    let attr_suffix = ""
    if has("gui")
        let vim_mode = "gui"
        let attr_suffix = "#"
    endif

    let value = synIDattr(synIDtrans(hlID(a:name)), a:attr . attr_suffix, vim_mode)

    return value
endfunction

function! s:SetHi(name, fg, bg)
    let vim_mode = "cterm"
    if has("gui")
        let vim_mode = "gui"
    endif

    let bg_spec = vim_mode . "bg=" . a:bg
    let fg_spec = vim_mode . "fg=" . a:fg
    let spec = bg_spec . " " . fg_spec
    exec "hi! " . a:name . " " . spec
endfunction

function! s:LinkHi(name, target)
    exec "hi! link " . a:name . " " . a:target
endfunction

function! s:SetColors()
    " TODO: try to match user's colorscheme
    call s:LinkHi("BuffetBuffer", "NonText")
    call s:LinkHi("BuffetActiveBuffer", "Cursor")
    call s:LinkHi("BuffetCurrentBuffer", "Search")
    call s:LinkHi("BuffetTab", "StatusLineTerm")
    call s:LinkHi("BuffetEnd", "TablineFill")
    call s:LinkHi("BuffetLeftTrunc", "ToolbarButton")
    call s:LinkHi("BuffetRightTrunc", "ToolbarButton")

    if exists("*g:BuffetSetCustomColors")
        call g:BuffetSetCustomColors()
    endif

    for left in keys(g:buffet_has_separator)
        for right in keys(g:buffet_has_separator[left])
            let vim_mode = "cterm"
            if has("gui")
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

augroup buffet_set_colors
    autocmd!
    autocmd ColorScheme * call s:SetColors()
augroup end

" Set solors also at the startup
call s:SetColors()

set tabline=%!buffet#render()
