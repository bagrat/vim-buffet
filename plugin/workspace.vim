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
if get(g:, "workspace_powerline_separators", 0)  " TODO: change default to 0
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

command! WSNext :call workspace#next()
command! WSPrev :call workspace#previous()
command! -bang WSClose :call workspace#delete("<bang>")

hi! WorkspaceBufferCurrentDefault cterm=NONE ctermbg=2 ctermfg=8
hi! WorkspaceBufferActiveDefault cterm=NONE ctermbg=10 ctermfg=2
hi! WorkspaceBufferHiddenDefault cterm=NONE ctermbg=10 ctermfg=8
hi! WorkspaceTabCurrentDefault cterm=NONE ctermbg=4 ctermfg=8
hi! WorkspaceTabHiddenDefault cterm=NONE ctermbg=4 ctermfg=8
hi! WorkspaceFillDefault cterm=NONE ctermbg=10 ctermfg=10
hi! WorkspaceIconDefault cterm=NONE ctermbg=5 ctermfg=10

hi link WorkspaceBufferCurrent WorkspaceBufferCurrentDefault
hi link WorkspaceBufferActive WorkspaceBufferActiveDefault
hi link WorkspaceBufferHidden WorkspaceBufferHiddenDefault
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
                \   "TabCurrent",
                \   "TabHidden",
                \   "Fill",
                \   "Icon",
                \ ]

    for left_hi in hi_groups
        for right_hi in hi_groups
            let hi_name = left_hi . right_hi
            let left_bg = synIDattr(synIDtrans(hlID("Workspace" . left_hi)), 'bg')
            let left_fg = synIDattr(synIDtrans(hlID("Workspace" . left_hi)), 'fg')
            let right_bg = synIDattr(synIDtrans(hlID("Workspace" . right_hi)), 'bg')
            let right_fg = synIDattr(synIDtrans(hlID("Workspace" . right_hi)), 'fg')

            if left_bg != right_bg
                exec "hi! Workspace" . hi_name . " ctermfg=" . left_bg . " ctermbg=" . right_bg    
            else
                let fg = left_fg

                if left_hi == "BufferActive"
                    let fg = synIDattr(synIDtrans(hlID("WorkspaceBufferHidden")), 'fg') 
                endif

                exec "hi! Workspace" . hi_name . " ctermfg=" . fg . " ctermbg=" . right_bg
            endif
        endfor
    endfor
endfunction

augroup set_colors_workspace
    autocmd!
    autocmd ColorScheme * call s:set_colors()
augroup end

" Set solors also at the startup
call s:SetColors()

set tabline=%!workspace#render()
