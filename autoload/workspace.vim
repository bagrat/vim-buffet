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
        let buf.is_active = (bufwinnr(bufno) > 0)
        let buf.is_current = (bufno == current_buffer)
        let buf.name = fnamemodify(bufname(bufno), ':t')
        let buf.label = -1

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

    return filtered_buffers
endfunction

function! s:GetRightTruncBuffer(count)
    let buf = {}
    let buf.type = 'Buffer'
    let buf.bufno = -1
    let buf.is_active = 0
    let buf.is_current = 0
    let buf.state = "Trunc"
    let buf.label = a:count . " " . g:workspace_right_trunc_icon

    return buf
endfunction

function! s:GetLeftTruncBuffer(count)
    let buf = {}
    let buf.type = 'Buffer'
    let buf.bufno = -1
    let buf.is_active = 0
    let buf.is_current = 0
    let buf.state = "Trunc"
    let buf.label = g:workspace_left_trunc_icon . " " . a:count

    return buf
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

function! s:RenderBuffer(prev, this, next)
    let bresult = ""

    let color = s:GetHighlight(a:this, 1)

    let right_sep = s:GetSeparator(a:this, a:next)

    let label = a:this.label
    if label == -1
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

function! s:BufferValueFits(bvalue, lvalue, tab_count, truncs)
    let sep_width = s:StrLen(g:workspace_separator)
    let subsep_width = s:StrLen(g:workspace_subseparator)
    let max_sep_width = max([sep_width, subsep_width])

    let tab_icon_width = s:StrLen(g:workspace_tab_icon)
    let tab_width = 1 + tab_icon_width + 1 + max_sep_width

    let ltrunc_icon_width = s:StrLen(g:workspace_left_trunc_icon)
    let rtrunc_icon_width = s:StrLen(g:workspace_right_trunc_icon)
    let max_trunc_icon_width = max([ltrunc_icon_width, rtrunc_icon_width])
    let trunc_width = a:truncs * (1 + max_trunc_icon_width + 1 + 2 + 1 + max_sep_width)

    let value_width = s:StrLen(a:bvalue)
    let line_width = s:StrLen(a:lvalue)

    let tabline_width = value_width + line_width + a:tab_count * tab_width + trunc_width
    
    return tabline_width < &columns
endfunction

function! s:ChopLeft(buffers, line)
    let chopped = a:buffers[0]
    let chopped_width = len(chopped[3])
    let buffers = a:buffers[1:]
    let line = a:line[chopped_width:]

    return [buffers, line]
endfunction

function! s:ChopRight(buffers, line)
    let chopped = a:buffers[-1]
    let chopped_width = len(chopped[3])
    let buffers = a:buffers[:-2]
    let line = a:line[:-chopped_width - 1]

    return [buffers, line]
endfunction

function! s:RenderTab(prev, this, next, tab_count)
    let color = s:GetHighlight(a:this, 1)
    let tab_label = color . " " . g:workspace_tab_icon . " "

    let buffer_line = ""
    if a:this.is_current
        let wbuffers = s:GetBuffers()
        let right_sep = s:GetSeparator(a:this, wbuffers[0])

        let fitting_buffers = []
        let current_index = -1
        let left_count = 0
        let left_chopped_count = 0
        let right_count = 0
        let right_chopped_count = 0
        let buffers_count = len(wbuffers)
        for wi in range(0, buffers_count - 1)
            let prev_buffer = wi > 0 ? wbuffers[wi - 1] : 0
            let this_buffer = wbuffers[wi]
            let next_buffer = wi < len(wbuffers) - 1 ? wbuffers[wi + 1] : a:next

            if this_buffer.is_current && current_index == -1
                let current_index = wi
            endif

            let left_count += current_index == -1 ? 1 : 0

            let buffer_value = s:RenderBuffer(prev_buffer, this_buffer, next_buffer)

            let done_drawing = 0
            let truncs_count = (left_chopped_count > 0 ? 1 : 0) + (right_chopped_count > 0 ? 1 : 0)
            while !s:BufferValueFits(buffer_value, buffer_line, a:tab_count, truncs_count) && len(fitting_buffers)
                if left_count < right_count
                    let done_drawing = 1
                    break
                endif
                let chop = s:ChopLeft(fitting_buffers, buffer_line)
                let fitting_buffers = chop[0]
                let buffer_line = chop[1]
                let left_chopped_count += 1
                let left_count -= 1
            endwhile

            if done_drawing
                break
            endif

            call add(fitting_buffers, [prev_buffer, this_buffer, next_buffer, buffer_value])
            let buffer_line = buffer_line . buffer_value
            let right_count += current_index > -1 && current_index != wi ? 1 : 0
            let right_chopped_count = buffers_count - (left_chopped_count + left_count + right_count + 1)
        endfor

        let right_chopped_count = len(wbuffers) - (left_chopped_count + left_count + right_count + 1)
        
        if left_chopped_count > 0
            let left_trunc = [0, s:GetLeftTruncBuffer(left_chopped_count), fitting_buffers[0][1]]
            let left_trunc_rendered = s:RenderBuffer(left_trunc[0], left_trunc[1], left_trunc[2])
            let left_chopped = fitting_buffers[0]
            let left_chopped[0] = left_trunc[1]
            let left_chopped_rendered = s:RenderBuffer(left_chopped[0], left_chopped[1], left_chopped[2])
            let buffer_line = left_trunc_rendered . left_chopped_rendered . s:ChopLeft(fitting_buffers, buffer_line)[1]
        endif

        if right_chopped_count > 0
            let right_trunc = [fitting_buffers[-1][1], s:GetRightTruncBuffer(right_chopped_count), a:next]
            let right_trunc_rendered = s:RenderBuffer(right_trunc[0], right_trunc[1], right_trunc[2])
            let right_chopped = fitting_buffers[-1]
            let right_chopped[2] = right_trunc[1]
            let right_chopped_rendered = s:RenderBuffer(right_chopped[0], right_chopped[1], right_chopped[2])
            let buffer_line = s:ChopRight(fitting_buffers, buffer_line)[1] . right_chopped_rendered . right_trunc_rendered
        endif
    else
        let right_sep = s:GetSeparator(a:this, a:next)
    endif

    let tab_label = color . " " . g:workspace_tab_icon . " "
    let tresult = tab_label . right_sep . buffer_line

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
