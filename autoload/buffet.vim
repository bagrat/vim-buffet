let s:buffers = {}
let s:buffer_ids = []

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
                " forget about this buffer
                call remove(s:buffers, buffer_id)
                call remove(s:buffer_ids, index(s:buffer_ids, buffer_id))
            endif

            continue
        endif

        " if this buffer is already tracked, we're good
        if is_present
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
endfunction

function! s:RenderBufferAtIndex(buffer_id_index)
    let current_buffer_id = bufnr('%')
    let buffer_id = s:buffer_ids[a:buffer_id_index]
    let buffer = s:buffers[buffer_id]

    let buffer_render = ""

    let buffer_render = buffer_render . " " . buffer.name

    if current_buffer_id == buffer_id
        let buffer_render = buffer_render . "*"
    endif

    return buffer_render
endfunction

function! s:RenderBuffers(length_limit)
    let current_buffer_id = bufnr('%')
    let buffers_render = ""

    let buffers_count = len(s:buffer_ids)
    let current_buffer_id_i = index(s:buffer_ids, current_buffer_id)

    let current_buffer = s:buffers[current_buffer_id]
    let capacity = a:length_limit - current_buffer.length
    let left_i = current_buffer_id_i
    let right_i = current_buffer_id_i

    for left_i in range(current_buffer_id_i - 1, 0, -1)
        let buffer = s:buffers[s:buffer_ids[left_i]]
        if buffer.length <= capacity
            let capacity = capacity - buffer.length
        else
            let left_i = left_i + 1
            break
        endif
    endfor

    for right_i in range(current_buffer_id_i + 1, buffers_count - 1)
        let buffer = s:buffers[s:buffer_ids[right_i]]
        if buffer.length <= capacity
            let capacity = capacity - buffer.length
        else
            let right_i = right_i - 1
            break
        endif
    endfor

    for i in range(left_i, right_i)
        let buffers_render = buffers_render . s:RenderBufferAtIndex(i)
    endfor

    let trunced_left = left_i
    let trunced_right = (buffers_count - right_i - 1)

    return trunced_left . " " . buffers_render . " " . trunced_right
endfunction

function! s:RenderTabs()
    let last_tab_id = tabpagenr('$')
    let current_tab_id = tabpagenr()

    let buffers_render = s:RenderBuffers(40)

    let tabs_render = ""
    for tab_id in range(1, last_tab_id)
        let tab_render = ""
        let tab_render = tab_render . " # "
        
        if tab_id == current_tab_id
            let tab_render = tab_render . buffers_render
        endif

        let tabs_render = tabs_render . tab_render
    endfor

    return tabs_render
endfunction

function! buffet#render()
    return s:RenderTabs()
endfunction
