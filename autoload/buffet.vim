let s:buffers = {}
let s:buffer_ids = []

" when the focus switches to another *unlisted* buffer, it does not appear in
" the tabline, thus the tabline will list starting from the first buffer. For
" this, we keep track of the last current buffer to keep the tabline "position"
" in the same place.
let s:last_current_buffer_id = -1

" when you delete a buffer with the highest ID, we will never loop up there and
" it will always stay in the buffers list, so we need to remember the largest
" buffer ID.
let s:largest_buffer_id = 1

" either a slash or backslash
let s:path_separator = fnamemodify(getcwd(),':p')[-1:]

function! buffet#update()
    let largest_buffer_id = max([bufnr('$'), s:largest_buffer_id])

    for buffer_id in range(1, largest_buffer_id)
        " Check if we already keep track of this buffer
        let is_present = 0
        if has_key(s:buffers, buffer_id)
            let is_present = 1
        endif

        " Skip if a buffer with this id does not exist
        if !buflisted(buffer_id)
            if is_present
                if buffer_id == s:last_current_buffer_id
                    let s:last_current_buffer_id = -1
                endif

                " forget about this buffer
                call remove(s:buffers, buffer_id)
                call remove(s:buffer_ids, index(s:buffer_ids, buffer_id))
                let s:largest_buffer_id = max(s:buffer_ids)
            endif

            continue
        endif

        " If this buffer is already tracked and listed, we're good.
        " In case if it is the only buffer, still update, because an empty new
        " buffer id is being replaced by a buffer for an existing file.
        if is_present && len(s:buffers) > 1
            continue
        endif

        " hide terminal and quickfix buffers
        let buffer_type = getbufvar(buffer_id, "&buftype", "")
        if index(["terminal", "quickfix"], buffer_type) >= 0
            call setbufvar(buffer_id, "&buflisted", 0)
            continue
        endif

        let buffer_name = bufname(buffer_id)
        let buffer_head = fnamemodify(buffer_name, ':p:h')
        let buffer_tail = fnamemodify(buffer_name, ':t')

        " Initialize the buffer object
        let buffer = {}
        let buffer.head = split(buffer_head, s:path_separator)
        let buffer.not_new = len(buffer_tail)
        let buffer.tail = buffer.not_new ? buffer_tail : g:buffet_new_buffer_name 

        " Update the buffers map
        let s:buffers[buffer_id] = buffer

        if !is_present
            " Update the buffer IDs list
            call add(s:buffer_ids, buffer_id)
            let s:largest_buffer_id = max([s:largest_buffer_id, buffer_id])
        endif
    endfor

    let buffer_name_count = {}

    " Set initial buffer name, and record occurrences
    for buffer in values(s:buffers)
        let buffer.index = -1
        let buffer.name = buffer.tail
        let buffer.length = len(buffer.name)

        if buffer.not_new
            let current_count = get(buffer_name_count, buffer.name, 0)
            let buffer_name_count[buffer.name] = current_count + 1
        endif
    endfor

    " Disambiguate buffer names with multiple occurrences
    while len(filter(buffer_name_count, 'v:val > 1'))
        let ambiguous = buffer_name_count
        let buffer_name_count = {}

        for buffer in values(s:buffers)
            if has_key(ambiguous, buffer.name)
                let buffer_path = buffer.head[buffer.index:]
                call add(buffer_path, buffer.tail)

                let buffer.index -= 1
                let buffer.name = join(buffer_path, s:path_separator)
                let buffer.length = len(buffer.name)
            endif

            if buffer.not_new
                let current_count = get(buffer_name_count, buffer.name, 0)
                let buffer_name_count[buffer.name] = current_count + 1
            endif
        endfor
    endwhile

    let current_buffer_id = bufnr('%')
    if has_key(s:buffers, current_buffer_id)
        let s:last_current_buffer_id = current_buffer_id
    elseif s:last_current_buffer_id == -1 && len(s:buffer_ids) > 0
        let s:last_current_buffer_id = s:buffer_ids[0]
    endif

    " Hide tabline if only one buffer and tab open
    if !g:buffet_always_show_tabline && len(s:buffer_ids) == 1 && tabpagenr("$") == 1
        set showtabline=0
    endif
endfunction

function! s:GetVisibleRange(length_limit, buffer_padding)
    let current_buffer_id = s:last_current_buffer_id

    if current_buffer_id == -1
        return [-1, -1]
    endif

    let current_buffer_id_i = index(s:buffer_ids, current_buffer_id)

    let current_buffer = s:buffers[current_buffer_id]
    let capacity = a:length_limit - current_buffer.length - a:buffer_padding
    let left_i = current_buffer_id_i
    let right_i = current_buffer_id_i

    for left_i in range(current_buffer_id_i - 1, 0, -1)
        let buffer = s:buffers[s:buffer_ids[left_i]]
        if (buffer.length + a:buffer_padding) <= capacity
            let capacity = capacity - buffer.length - a:buffer_padding
        else
            let left_i = left_i + 1
            break
        endif
    endfor

    for right_i in range(current_buffer_id_i + 1, len(s:buffers) - 1)
        let buffer = s:buffers[s:buffer_ids[right_i]]
        if (buffer.length + a:buffer_padding) <= capacity
            let capacity = capacity - buffer.length - a:buffer_padding
        else
            let right_i = right_i - 1
            break
        endif
    endfor

    return [left_i, right_i]
endfunction

function! s:GetBufferElements(capacity, buffer_padding)
    let [left_i, right_i] = s:GetVisibleRange(a:capacity, a:buffer_padding)
    " TODO: evaluate if calling this ^ twice will get better visuals

    if left_i < 0 || right_i < 0
        return []
    endif

    let buffer_elems = []

    let trunced_left = left_i
    if trunced_left
        let left_trunc_elem = {}
        let left_trunc_elem.type = "LeftTrunc"
        let left_trunc_elem.value = g:buffet_left_trunc_icon . " " . trunced_left
        call add(buffer_elems, left_trunc_elem)
    endif

    for i in range(left_i, right_i)
        let buffer_id = s:buffer_ids[i]
        let buffer = s:buffers[buffer_id]

        if buffer_id == winbufnr(0)
            let type_prefix = "Current"
        elseif bufwinnr(buffer_id) > 0
            let type_prefix = "Active"
        else
            let type_prefix = ""
        endif

        let elem = {}
        let elem.index = i + 1
        let elem.value = buffer.name
        let elem.buffer_id = buffer_id
        let elem.is_modified = getbufvar(buffer_id, '&mod')

        if elem.is_modified
            let type_prefix = "Mod" . type_prefix
        endif

        let elem.type = type_prefix . "Buffer"

        call add(buffer_elems, elem)
    endfor

    let trunced_right = (len(s:buffers) - right_i - 1)
    if trunced_right > 0
        let right_trunc_elem = {}
        let right_trunc_elem.type = "RightTrunc"
        let right_trunc_elem.value = trunced_right . " " . g:buffet_right_trunc_icon
        call add(buffer_elems, right_trunc_elem)
    endif

    return buffer_elems
endfunction

function! s:GetAllElements(capacity, buffer_padding)
    let last_tab_id = tabpagenr('$')
    let current_tab_id = tabpagenr()
    let buffer_elems = s:GetBufferElements(a:capacity, a:buffer_padding)
    let tab_elems = []

    for tab_id in range(1, last_tab_id)
        let elem = {}
        let elem.value = tab_id
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
    if index(g:buffet_buffer_types, a:element.type) >= 0
        return 1
    endif

    return 0
endfunction

function! s:Len(string)
    let visible_singles = substitute(a:string, '[^\d0-\d127]', "-", "g")

    return len(visible_singles)
endfunction

function! s:GetTypeHighlight(type)
    return "%#" . g:buffet_prefix . a:type . "#"
endfunction

function! s:Render()
    let sep_len = s:Len(g:buffet_separator)

    let tabs_count = tabpagenr("$")
    let tabs_len = (1 + s:Len(g:buffet_tab_icon) + 1 + sep_len) * tabs_count

    let left_trunc_len = 1 + s:Len(g:buffet_left_trunc_icon) + 1 + 2 + 1 + sep_len
    let right_trunc_len =  1 + 2 + 1 + s:Len(g:buffet_right_trunc_icon) + 1 + sep_len
    let trunc_len = left_trunc_len + right_trunc_len

    let capacity = &columns - tabs_len - trunc_len - 5
    let buffer_padding = 1 + (g:buffet_use_devicons ? 1+1 : 0) + 1 + sep_len

    let elements = s:GetAllElements(capacity, buffer_padding)

    let render = ""
    for i in range(0, len(elements) - 2)
        let left = elements[i]
        let elem = left
        let right = elements[i + 1]

        if elem.type == "Tab"
            let render = render . "%" . elem.value . "T"
        elseif s:IsBufferElement(elem) && has("nvim")
            let render = render . "%" . elem.buffer_id . "@SwitchToBuffer@"
        endif

        let highlight = s:GetTypeHighlight(elem.type)
        let render = render . highlight

        if g:buffet_show_index && s:IsBufferElement(elem)
            let render = render . " " . elem.index
        endif

        let icon = ""
        if g:buffet_use_devicons && s:IsBufferElement(elem)
            let icon = " " . WebDevIconsGetFileTypeSymbol(elem.value)
        elseif elem.type == "Tab"
            let icon = " " . g:buffet_tab_icon
        endif

        let render = render . icon

        if elem.type != "Tab"
            let render = render . " " . elem.value
        endif

        if s:IsBufferElement(elem)
            if elem.is_modified && g:buffet_modified_icon != ""
                let render = render . g:buffet_modified_icon
            endif
        endif

        let render = render . " "

        let separator =  g:buffet_has_separator[left.type][right.type]
        let separator_hi = s:GetTypeHighlight(left.type . right.type)
        let render = render . separator_hi . separator

        if elem.type == "Tab" && has("nvim")
            let render = render . "%T"
        elseif s:IsBufferElement(elem) && has("nvim")
            let render = render . "%T"
        endif
    endfor

    if !has("nvim")
        let render = render . "%T"
    endif

    let render = render . s:GetTypeHighlight("Buffer")

    return render
endfunction

function! buffet#render()
    call buffet#update()
    return s:Render()
endfunction

function! s:GetBuffer(buffer)
    if empty(a:buffer) && s:last_current_buffer_id >= 0
        let btarget = s:last_current_buffer_id
    elseif a:buffer =~ '^\d\+$'
        let btarget = bufnr(str2nr(a:buffer))
    else
        let btarget = bufnr(a:buffer)
    endif

    return btarget
endfunction

function! buffet#bswitch(index)
    let i = str2nr(a:index) - 1
    if i < 0 || i > len(s:buffer_ids) - 1
        echohl ErrorMsg
        echom "Invalid buffer index"
        echohl None
        return
    endif
    let buffer_id = s:buffer_ids[i]
    execute 'silent buffer ' . buffer_id
endfunction

" inspired and based on https://vim.fandom.com/wiki/Deleting_a_buffer_without_closing_the_window
function! buffet#bwipe(bang, buffer)
    let btarget = s:GetBuffer(a:buffer)

    let filters = get(g:, "buffet_bwipe_filters", [])
    if type(filters) == type([])
        for f in filters
            if function(f)(a:bang, btarget) > 0
                return
            endif
        endfor
    endif

    if btarget < 0
        echohl ErrorMsg
        call 'No matching buffer for ' . a:buffer
        echohl None

        return
    endif

    if empty(a:bang) && getbufvar(btarget, '&modified')
        echohl ErrorMsg
        echom 'No write since last change for buffer ' . btarget . " (add ! to override)"
        echohl None
        return
    endif

    " IDs of windows that view target buffer which we will delete.
    let wnums = filter(range(1, winnr('$')), 'winbufnr(v:val) == btarget')

    let wcurrent = winnr()
    for w in wnums
        " switch to window with ID 'w'
        execute 'silent ' . w . 'wincmd w'

        let prevbuf = bufnr('#')
        " if the previous buffer is another listed buffer, switch to it...
        if prevbuf > 0 && buflisted(prevbuf) && prevbuf != btarget
            buffer #
        " ...otherwise just go to the previous buffer in the list.
        else
            bprevious
        endif

        " if the 'bprevious' did not work, then just open a new buffer
        if btarget == bufnr("%")
            execute 'silent enew' . a:bang
        endif
    endfor

    " finally wipe the tarbet buffer
    execute 'silent bwipe' . a:bang . " " . btarget
    " switch back to original window
    execute 'silent ' . wcurrent . 'wincmd w'
endfunction

function! buffet#bonly(bang, buffer)
    let btarget = s:GetBuffer(a:buffer)

    for b in s:buffer_ids
        if b == btarget
            continue
        endif

        call buffet#bwipe(a:bang, b)
    endfor
endfunction
