if exists("g:workspace_loaded")
    finish
endif

let g:workspace_loaded = 1


if get(g:, "workspace_always_show_tabline", 1)
    set showtabline=2
endif


" People either use the defaults, make their own customization or guess what?
" Powerline separators! So better to ease the users life and provide a switch
" for that.
if get(g:, "workspace_powerline_separators", 0)
    let g:workspace_powerline_separators = 1
    let g:workspace_separator = "\ue0b0"
    let g:workspace_subseparator = "\ue0b1"
else
    let g:workspace_powerline_separators = 0
    let g:workspace_separator = get(g:, "workspace_separator", "")
    let g:workspace_subseparator = get(g:, "workspace_subseparator", "|")
endif

" If we find devicons installed, then the user would like some nice icon stuff
if get(g:, "workspace_use_devicons", 1)
    if !exists("*WebDevIconsGetFileTypeSymbol")
        let g:workspace_use_devicons = 0
    else
        let g:workspace_use_devicons = 1
    endif
else
    let g:workspace_use_devicons = 0
endif

if !exists("g:workspace_hide_buffers")
    let g:workspace_hide_buffers = []
endif

if !exists("g:workspace_tab_icon")
    let g:workspace_tab_icon = "#"
endif

if !exists("g:workspace_hide_ft_buffers")
    let g:workspace_hide_ft_buffers = ['qf']
endif

if !exists("g:workspace_new_buffer_name")
    let g:workspace_new_buffer_name = "*"
endif

if !exists("g:workspace_modified_icon")
    let g:workspace_modified_icon = "+"
endif

if !exists("g:workspace_left_trunc_icon")
    let g:workspace_left_trunc_icon = "<"
endif

if !exists("g:workspace_right_trunc_icon")
    let g:workspace_right_trunc_icon = ">"
endif

command! WSNext :call workspace#next()
command! WSPrev :call workspace#previous()
command! WSTabNew :call workspace#newtab()
command! -bang WSClose :call workspace#delete("<bang>")
command! -bang WSBufOnly :call workspace#bufonly("<bang>")

hi WorkspaceErrorText cterm=bold ctermbg=8 ctermfg=1 guibg=#000000 guifg=#FF0000
hi WorkspaceError cterm=bold ctermbg=1 ctermfg=8 guibg=#FF0000 guifg=#000000

hi! WorkspaceBufferCurrentDefault cterm=NONE ctermbg=2 ctermfg=8 guibg=#00FF00 guifg=#000000
hi! WorkspaceBufferActiveDefault cterm=NONE ctermbg=10 ctermfg=2 guibg=#999999 guifg=#00FF00
hi! WorkspaceBufferHiddenDefault cterm=NONE ctermbg=10 ctermfg=8 guibg=#999999 guifg=#000000
hi! WorkspaceBufferTruncDefault cterm=bold ctermbg=10 ctermfg=8 guibg=#999999 guifg=#000000
hi! WorkspaceTabCurrentDefault cterm=NONE ctermbg=4 ctermfg=8 guibg=#0000FF guifg=#000000
hi! WorkspaceTabHiddenDefault cterm=NONE ctermbg=4 ctermfg=8 guibg=#0000FF guifg=#000000
hi! WorkspaceFillDefault cterm=NONE ctermbg=10 ctermfg=10 guibg=#999999 guifg=#999999
hi! WorkspaceIconDefault cterm=NONE ctermbg=5 ctermfg=10 guibg=#FF0000 guifg=#999999

hi link WorkspaceBufferCurrent WorkspaceBufferCurrentDefault
hi link WorkspaceBufferActive WorkspaceBufferActiveDefault
hi link WorkspaceBufferHidden WorkspaceBufferHiddenDefault
hi link WorkspaceBufferTrunc WorkspaceBufferTruncDefault
hi link WorkspaceTabCurrent WorkspaceTabCurrentDefault
hi link WorkspaceTabHidden WorkspaceTabHiddenDefault
hi link WorkspaceFill WorkspaceFillDefault
hi link WorkspaceIcon WorkspaceIconDefault

function! s:SetColors()
    if exists("*g:WorkspaceSetCustomColors")
        call g:WorkspaceSetCustomColors()
    endif

    if !g:workspace_powerline_separators
        return
    endif

    let hi_groups = [
                \   "BufferCurrent",
                \   "BufferActive",
                \   "BufferHidden",
                \   "BufferTrunc",
                \   "TabCurrent",
                \   "TabHidden",
                \   "Fill",
                \ ]

    for left_hi in hi_groups
        for right_hi in hi_groups
            let hi_name = left_hi . right_hi
            let left_bg = synIDattr(synIDtrans(hlID("Workspace" . left_hi)), 'bg', 'cterm')
            let left_fg = synIDattr(synIDtrans(hlID("Workspace" . left_hi)), 'fg', 'cterm')
            let right_bg = synIDattr(synIDtrans(hlID("Workspace" . right_hi)), 'bg', 'cterm')
            let right_fg = synIDattr(synIDtrans(hlID("Workspace" . right_hi)), 'fg', 'cterm')

            let left_bgh = synIDattr(synIDtrans(hlID("Workspace" . left_hi)), 'bg#', 'gui')
            let left_fgh = synIDattr(synIDtrans(hlID("Workspace" . left_hi)), 'fg#', 'gui')
            let right_bgh = synIDattr(synIDtrans(hlID("Workspace" . right_hi)), 'bg#', 'gui')
            let right_fgh = synIDattr(synIDtrans(hlID("Workspace" . right_hi)), 'fg#', 'gui')

            if left_bg != right_bg || left_bgh != right_bgh
                exec "hi! Workspace" . hi_name . " ctermfg=" . left_bg . " ctermbg=" . right_bg
                            \ . " guifg=" . left_bgh . " guibg=" . right_bgh
            else
                let fg = left_fg
                let fgh = left_fgh

                if left_hi == "BufferActive" || left_hi == "BufferTrunc"
                    let fg = synIDattr(synIDtrans(hlID("WorkspaceBufferHidden")), 'fg', 'cterm')
                    let fgh = synIDattr(synIDtrans(hlID("WorkspaceBufferHidden")), 'fg#', 'gui') 
                endif

                exec "hi! Workspace" . hi_name . " ctermfg=" . fg . " ctermbg=" . right_bg
                            \ . " guifg=" . fgh . " guibg=" . right_bgh
            endif
        endfor
    endfor
endfunction

augroup set_colors_workspace
    autocmd!
    autocmd ColorScheme * call s:SetColors()
augroup end

" Set solors also at the startup
call s:SetColors()

set tabline=%!workspace#render()
