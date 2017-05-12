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

    let hi_name = "Workspace" . left_hi . right_hi

    return "%#" . hi_name . "#" . sep
endfunction

function! s:RenderBuffer(prev_tab, prev, this, next, next_tab)
    let bresult = ""

    let color = s:GetHighlight(a:this, 1)

    let global_next = a:this.is_last ? a:next_tab : a:next
    let right_sep = s:GetSeparator(a:this, global_next)

    let buffer_label = color . " " . a:this.name . " "
    let bresult = buffer_label . right_sep

    return bresult
endfunction

function! s:RenderTab(prev, this, next)
    let color = s:GetHighlight(a:this, 1)

    let buffer_result = ""
    if a:this.is_current
        let wbuffers = s:GetBuffers()
        let right_sep = s:GetSeparator(a:this, wbuffers[0])
        
        for wi in range(0, len(wbuffers) - 1)
            let prev_buffer = wi > 0 ? wbuffers[wi - 1] : 0
            let this_buffer = wbuffers[wi]
            let next_buffer = wi < len(wbuffers) - 1 ? wbuffers[wi + 1] : 0

            let buffer_result = buffer_result . s:RenderBuffer(a:this, prev_buffer, this_buffer, next_buffer, a:next)
        endfor
    else
        let right_sep = s:GetSeparator(a:this, a:next)
    endif

    let tab_label = color . " ". a:this.tabno . " "
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

        let line = line . s:RenderTab(prev_tab, this_tab, next_tab)
    endfor

    return line . "%#WorkspaceFill#"
endfunction

function! workspace#next()
    let wbuffers = s:GetBuffers()
    
    if len(wbuffers) == 0
        return
    endif

    let hit_current = 0
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

    exec "buffer " . next_buf
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

    exec "buffer " . last_seen
endfunction

" TODO: Add bang behind a command
function! workspace#delete()
    let wbuffers = s:GetBuffers()
    
    let this = winbufnr(0)

    if len(wbuffers) == 1
        exec "enew"
        exec this . "bwipe"
        return
    endif
     
    call workspace#next()
    exec this . "bwipe"
    call workspace#previous()
endfunction
