let s:buffers = {}
let s:buffer_ids = []

" TODO: comment about the need of this
let s:last_current_buffer_id = 0

function! buffet#update()
    let last_buffer_id = bufnr('$')

    for buffer_id in range(1, last_buffer_id)
        " Check if we already keep track of this buffer
        let is_present = 0
        if has_key(s:buffers, buffer_id)
            let is_present = 1
        endif

        " Skip if a buffer with this id does not exist
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

        " If this buffer is already tracked and listed, we're good.
        " In case if it is the only buffer, still update, because an empty new
        " buffer id is being replaced by a buffer for an existing file.
        if is_present && len(s:buffers) > 1
            continue
        endif

        " Initialize the buffer object
        let buffer_name = bufname(buffer_id)
        let buffer = {}
        let buffer.name = fnamemodify(buffer_name, ':t')
        let buffer.length = len(buffer.name)

        if buffer.name == ""
            let buffer.name = "@"
        endif

        let buffer.name_length = len(buffer.name)
        let buffer.is_active = (bufwinnr(buffer_id) > 0)

        " Update the buffers map
        let s:buffers[buffer_id] = buffer

        if !is_present
            " Update the buffer IDs list
            call add(s:buffer_ids, buffer_id)
        endif
    endfor

    let current_buffer_id = bufnr('%')
    if has_key(s:buffers, current_buffer_id)
        let s:last_current_buffer_id = current_buffer_id
    endif
endfunction

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

function! s:GetBufferElements(capacity)
    let [left_i, right_i] = s:GetVisibleRange(a:capacity)
    let buffer_elems = []

    let trunced_left = left_i
    if trunced_left
        let left_trunc_elem = {}
        let left_trunc_elem.type = "LeftTrunc"
        let left_trunc_elem.value = trunced_left
        call add(buffer_elems, left_trunc_elem)
    endif

    for i in range(left_i, right_i)
        let buffer_id = s:buffer_ids[i]
        let buffer = s:buffers[buffer_id]

        let elem = {}
        let elem.value = buffer.name
        let elem.type = "Buffer"
        let elem.buffer = buffer

        call add(buffer_elems, elem)
    endfor

    let trunced_right = (len(s:buffers) - right_i - 1)
    if trunced_right
        let right_trunc_elem = {}
        let right_trunc_elem.type = "RightTrunc"
        let right_trunc_elem.value = trunced_right
        call add(buffer_elems, right_trunc_elem)
    endif

    return buffer_elems
endfunction

function! s:GetAllElements(capacity)
    let last_tab_id = tabpagenr('$')
    let current_tab_id = tabpagenr()
    let buffer_elems = s:GetBufferElements(a:capacity)
    let tab_elems = []

    for tab_id in range(1, last_tab_id)
        let elem = {}
        let elem.value = "#"
        let elem.type = "Tab"
        call add(tab_elems, elem)
        
        if tab_id == current_tab_id
            let tab_elems = tab_elems + buffer_elems
        endif
    endfor

    let end_elem = {"type": "End", "value": ""}
    call add(tab_elems, end_elem)

    return tab_elems
endfunction

function! s:IsBufferElement(element)
    if index(["Buffer", "ActiveBuffer", "CurrentBuffer"], element.type) >= 0
        return 1
    endif

    return 0
endfunction

function! s:Render()
    " TODO: revisit
    let capacity = &columns - 15
    let elements = s:GetAllElements(capacity)

    let render = ""
    for i in range(0, len(elements) - 2)
        let left = elements[i]
        let elem = left
        let right = elements[i + 1]

        let highlight = "%#" . g:buffet_prefix . elem.type . "#"
        let render = render . highlight . " " . elem.value . " "

        if g:buffet_has_separator[left.type][right.type]
            let render = render . "|"
        endif
    endfor

    return render
endfunction

function! buffet#render()
    call buffet#update()
    return s:Render()
endfunction
