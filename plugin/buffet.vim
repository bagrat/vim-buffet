autocmd VimEnter,BufEnter * call buffet#update()

set showtabline=2
set tabline=%!buffet#render()
