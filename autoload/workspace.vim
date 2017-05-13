function! s:GetBuffers()
    let last_buffer = bufnr('$')
    let filtered_buffers = []
    let current_buffer = winbufnr(0)

    let hide_buffers = get(g:, "workspace_hide_buffers", [])
    let hide_ft_buffers = get(g:, "workspace_hide_ft_buffers", [])

    for bufno in range(1, last_buffer)
        if !bufexists(bufno)
            continue
        endif

        if !buflisted(bufno)
            continue
        endif

        if index(hide_buffers, bufname(bufno)) >= 0
            continue
        endif

        if index(hide_ft_buffers, getbufvar(bufno, '&filetype')) >= 0
            continue
        endif

        let buf = {}
        let buf.type = 'Buffer'
        let buf.bufno = bufno
        let buf.is_first = 0
        let buf.is_last = 0
        let buf.is_active = (bufwinnr(bufno) > 0)
        let buf.is_current = (bufno == current_buffer)
        let buf.name = fnamemodify(bufname(bufno), ':t')

        if buf.is_current
            let buf.state = "Current"
        elseif buf.is_active
            let buf.state = "Active"
        else
            let buf.state = "Hidden"
        endif

        if buf.name == ""
            let buf.name = g:workspace_new_buffer_name
        endif

        call add(filtered_buffers, buf)
    endfor

    let filtered_buffers[0].is_first = 1
    let filtered_buffers[-1].is_last = 1

    return filtered_buffers
endfunction

function! s:GetTabs()
    let all_tabs = []

    for tabno in range(1, tabpagenr('$'))
        let tab = {}
        let tab.type = 'Tab'
        let tab.tabno = tabno
        let tab.is_first = 0
        let tab.is_last = 0
        let tab.is_current = (tabno == tabpagenr())

        if tab.is_current
            let tab.state = "Current"
        else
            let tab.state = "Hidden"
        endif

        call add(all_tabs, tab)
    endfor

    let all_tabs[0].is_first = 1
    let all_tabs[-1].is_last= 1

    return all_tabs
endfunction

function! s:GetHighlight(obj, for_tabline)
    let obj_hi = ""
    if type(a:obj) == 4
        let obj_hi = a:obj.type . a:obj.state

        if a:for_tabline
            let obj_hi = "%#Workspace" . obj_hi . "#"
        endif
    endif

    return obj_hi
endfunction

function! s:GetSeparator(left, right)
    let left_hi = s:GetHighlight(a:left, 0)
    let right_hi = s:GetHighlight(a:right, 0)

    if right_hi == ""
        let right_hi = "Fill"
    endif

    let left_bg = synIDattr(synIDtrans(hlID("Workspace" . left_hi)), 'bg')
    let right_bg = synIDattr(synIDtrans(hlID("Workspace" . right_hi)), 'bg')

    if left_bg != right_bg
        let sep = g:workspace_separator
    else
        let sep = g:workspace_subseparator
    endif

    if !g:workspace_powerline_separators
        return sep
    endif

    let hi_name = "Workspace" . left_hi . right_hi

    return "%#" . hi_name . "#" . sep
endfunction

function! s:RenderBuffer(prev_tab, prev, this, next, next_tab, label)
    let bresult = ""

    let color = s:GetHighlight(a:this, 1)

    let global_next = a:this.is_last ? a:next_tab : a:next
    let right_sep = s:GetSeparator(a:this, global_next)

    let label = a:label
    if !label
        let name = a:this.name
        if g:workspace_use_devicons
            let name = WebDevIconsGetFileTypeSymbol(name) . name
        endif

        let modified_icon = ""
        if getbufvar(a:this.bufno, '&mod') && g:workspace_modified_icon != ""
            let modified_icon = " " . g:workspace_modified_icon
        endif

        let label = name . modified_icon
    endif

    let buffer_label = color . " " . label . " "
    let bresult = buffer_label . right_sep

    return bresult
endfunction

function! s:StrLen(string)
    let visible = substitute(a:string, "%#[^#]\\+#", "", "g")
    let unicodes = substitute(visible, '[\d0-\d127]', "", "g")
    let dashes = substitute(unicodes, '[^\d0-\d127]', "-", "g")
    let no_unicodes = substitute(visible, '[^\d0-\d127]', "", "g")
    let length = len(no_unicodes) + len(dashes)

    return length
endfunction

let s:last_left = 0
let s:last_right = 0
let s:last_current = 0
function! s:RenderTab(prev, this, next, tabs_count)
    let color = s:GetHighlight(a:this, 1)
    let tab_label = color . " " . g:workspace_tab_icon . " "

    let buffer_result = ""
    if a:this.is_current
        let wbuffers = s:GetBuffers()
        let right_sep = s:GetSeparator(a:this, wbuffers[0])

        for wi in range(0, len(wbuffers) - 1)
            let prev_buffer = wi > 0 ? wbuffers[wi - 1] : 0
            let this_buffer = wbuffers[wi]
            let next_buffer = wi < len(wbuffers) - 1 ? wbuffers[wi + 1] : 0

            let bresult = s:RenderBuffer(a:this, prev_buffer, this_buffer, next_buffer, a:next, 0)

            let buffer_result = buffer_result . bresult
        endfor
    else
        let right_sep = s:GetSeparator(a:this, a:next)
    endif

    let tab_label = color . " " . g:workspace_tab_icon . " "
    let tresult = tab_label . right_sep . buffer_result

    return tresult
endfunction

function! workspace#render()
    let wtabs = s:GetTabs()

    let line = ""
    for wi in range(0, len(wtabs) - 1)
        let prev_tab = wi > 0 ? wtabs[wi - 1] : 0
        let this_tab = wtabs[wi]
        let next_tab = wi < len(wtabs) - 1 ? wtabs[wi + 1] : 0

        let tresult = s:RenderTab(prev_tab, this_tab, next_tab, len(wtabs))

        let line = line . tresult
    endfor

    return line . "%#WorkspaceFill#"
endfunction

function! workspace#next()
    let wbuffers = s:GetBuffers()
    
    if len(wbuffers) == 0
        return
    endif

    let hit_current = 0
    let next_buf = -1
    for wbuf in wbuffers
        if hit_current == 1
            let next_buf = wbuf.bufno
            let hit_current = 2
            break
        else
            let hit_current = wbuf.is_current ? 1 : 0
        endif
    endfor

    if hit_current == 1
        let next_buf = wbuffers[0].bufno
    endif

    if next_buf > 0
        exec "silent buffer " . next_buf
    endif 
endfunction


function! workspace#previous()
    let wbuffers = s:GetBuffers()
    
    if len(wbuffers) == 1
        return
    endif

    let last_seen = -1
    for wbuf in wbuffers
        if wbuf.is_current
            break
        else
            let last_seen = wbuf.bufno
        endif
    endfor

    if last_seen == -1
        let last_seen = wbuffers[-1].bufno
    endif

    exec "silent buffer " . last_seen
endfunction

function! workspace#delete(bang)
    let wbuffers = s:GetBuffers()
    
    let this = -1
    for wbuf in wbuffers
        if wbuf.is_current
            let this = wbuf.bufno
            break
        endif
    endfor

    if this == -1
        return
    endif

    let that = -1

    if len(wbuffers) == 1
        exec "silent enew"
        let that = winbufnr(0)
    else
        call workspace#next()
    endif
     
    try
        exec "silent " . this . "bwipe" . a:bang
    catch /^Vim\%((\a\+)\)\=:E89/
        if that > 0
            exec "silent " . that . "bwipe"
        endif
        if g:workspace_use_devicons
            echohl WorkspaceError
            echo "  \uf0c7\uf12a "
            echohl None
            echohl WorkspaceErrorText
            echon g:workspace_separator . " "
            echohl None
        else
            echon "Error: "
        endif
        echohl WorkspaceErrorText
        echon "This file has unsaved changes. If you are sure, use force close (:WSClose!)"
        echohl None
    endtry
    call workspace#previous()
endfunction

function! workspace#newtab()
    let wbuffers = s:GetBuffers()
    
    let current = -1
    let active = -1
    for wbuf in wbuffers
        if wbuf.is_current
            let current = wbuf.bufno
            break
        elseif wbuf.is_active && active == -1
            let active = wbuf.bufno        
        endif
    endfor
    
    if current == -1
        if active == -1
            let this = wbuffers[0].bufno
        else
            let this = active
        endif
    else
        let this = current
    endif

    exec "tabnew " . bufname(this)
endfunction
