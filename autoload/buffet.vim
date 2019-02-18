
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
        let buffer.is_active = (bufwinnr(buffer_id) > 0)

        " update the buffers map
        let s:buffers[buffer_id] = buffer
        " update the buffer IDs list
        call add(s:buffer_ids, buffer_id)
    endfor
endfunction

function! s:RenderBuffers()
    let current_buffer_id = bufnr('%')
    let buffers_render = ""
    for buffer_id in s:buffer_ids
        let buffer = s:buffers[buffer_id]
        let buffer_render = ""

        let buffer_render = buffer_render . " " . buffer.name

        if current_buffer_id == buffer_id
            let buffer_render = buffer_render . "*"
        endif

        let buffers_render = buffers_render . buffer_render
    endfor

    return buffers_render
endfunction

function! s:RenderTabs()
    let last_tab_id = tabpagenr('$')
    let current_tab_id = tabpagenr()

    let buffers_render = s:RenderBuffers()

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
