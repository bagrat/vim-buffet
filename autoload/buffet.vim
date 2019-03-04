let s:buffers = {}
let s:buffer_ids = []

" TODO: comment about the need of this
let s:last_current_buffer_id = 0

function! buffet#update()
    let last_buffer_id = bufnr('$')

    for buffer_id in range(1, last_buffer_id)
        " check if we already keep track of this buffer
        let is_present = 0
        if has_key(s:buffers, buffer_id)
            let is_present = 1
        endif

        " skip if a buffer with this id does not exist
        if !buflisted(buffer_id)
            if is_present
                if buffer_id == s:last_current_buffer_id
                    let s:last_current_buffer_id = s:buffer_ids[0]
                endif

                " forget about this buffer
                call remove(s:buffers, buffer_id)
                call remove(s:buffer_ids, index(s:buffer_ids, buffer_id))
            endif

            continue
        endif

        " if this buffer is already tracked and listed, we're good
        if is_present && len(s:buffers) > 1
            continue
        endif

        " initialize the buffer object
        let buffer_name = bufname(buffer_id)
        let buffer = {}
        let buffer.name = fnamemodify(buffer_name, ':t')
        let buffer.length = len(buffer.name)

        if buffer.name == ""
            let buffer.name = "@"
        endif

        let buffer.name_length = len(buffer.name)
        let buffer.is_active = (bufwinnr(buffer_id) > 0)

        " update the buffers map
        let s:buffers[buffer_id] = buffer
        " update the buffer IDs list
        call add(s:buffer_ids, buffer_id)
    endfor

    let current_buffer_id = bufnr('%')
    if has_key(s:buffers, current_buffer_id)
        let s:last_current_buffer_id = current_buffer_id
    endif
endfunction

function! s:RenderBufferAtIndex(buffer_id_index)
    let buffer_id = s:buffer_ids[a:buffer_id_index]
    let buffer = s:buffers[buffer_id]

    let buffer_render = buffer.name

    let current_buffer_id = bufnr("%")
    if buffer_id == current_buffer_id
        let buffer_render = buffer_render . "*"
    endif

    return buffer_render
endfunction

" TODO: think maybe better to paginate the tabs. for better visuals

function! s:GetVisibleRange(length_limit)
    let current_buffer_id = s:last_current_buffer_id
    let current_buffer_id_i = index(s:buffer_ids, current_buffer_id)

    let current_buffer = s:buffers[current_buffer_id]
    let buffer_padding = 3
    let capacity = a:length_limit - current_buffer.length - buffer_padding
    let left_i = current_buffer_id_i
    let right_i = current_buffer_id_i

    for left_i in range(current_buffer_id_i - 1, 0, -1)
        let buffer = s:buffers[s:buffer_ids[left_i]]
        if (buffer.length + buffer_padding) <= capacity
            let capacity = capacity - buffer.length - buffer_padding
        else
            let left_i = left_i + 1
            break
        endif
    endfor

    for right_i in range(current_buffer_id_i + 1, len(s:buffers) - 1)
        let buffer = s:buffers[s:buffer_ids[right_i]]
        if (buffer.length + buffer_padding) <= capacity
            let capacity = capacity - buffer.length - buffer_padding
        else
            let right_i = right_i - 1
            break
        endif
    endfor

    return [left_i, right_i]
endfunction

function! s:RenderBuffers(length_limit)
    let [left_i, right_i] = s:GetVisibleRange(a:length_limit)

    let buffers_render = ""

    let trunced_left = left_i
    if trunced_left
        let buffers_render = " <" . trunced_left . " |"
    endif

    for i in range(left_i, right_i)
        let buffers_render = buffers_render . " " . s:RenderBufferAtIndex(i) . " |"
    endfor

    let trunced_right = (len(s:buffers) - right_i - 1)
    if trunced_right
        let buffers_render = buffers_render . " " . trunced_right . "> |"
    endif

    return buffers_render
endfunction

function! s:RenderTabs()
    let last_tab_id = tabpagenr('$')
    let current_tab_id = tabpagenr()

    " FIXME: make this more readable after
    let capacity = &columns - 2 * (2 + 4) - last_tab_id * 4 
    let buffers_render = s:RenderBuffers(capacity)

    let tabs_render = ""
    for tab_id in range(1, last_tab_id)
        let tab_render = ""
        let tab_render = tab_render . " # |"
        
        if tab_id == current_tab_id
            let tab_render = tab_render . buffers_render
        endif

        let tabs_render = tabs_render . tab_render
    endfor

    return tabs_render
endfunction

function! buffet#render()
    call buffet#update()
    return s:RenderTabs()
endfunction
