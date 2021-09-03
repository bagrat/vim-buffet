<h1 align="center">
  <br>
  <img src="https://image.flaticon.com/icons/svg/531/531193.svg" alt="Markdownify" width="250">
  <br>
    𝓿𝓲𝓶 -𝓫𝓾𝓯𝓯𝓮𝓽
  <br>
</h1>

<p align="center">
  <b>Brings you the IDE-like tabs into Vim, for easy navigation, and a nice, customizable look</b>
</p>

<p align="center">
  <a href="https://gitter.im/vim-buffet/vim-buffet?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge" target="_blank">
    <img src="https://img.shields.io/badge/%F0%9F%92%AC-gitter-%23e74f4e">
  </a>
  <!--
  <a href="https://saythanks.io/to/amitmerchant1990">
      <img src="https://img.shields.io/badge/SayThanks.io-%E2%98%BC-1EAEDB.svg">
  </a>
  -->
</p>

<p align="center">
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#recommendations">Recommendations</a> •
  <a href="#faq">FAQ</a> •
  <a href="#credits">Credits</a> •
  <a href="#license">License</a>
</p>

**Note:** This plugin has been renamed from `vim-workspace` and thus has also
different prefix for the configuration and commands. Please revisit the README
and use the new names of the configuration parameters, highlight groups and
commands. Sorry for inconvenience.



## Introduction
<h3 align="center">
    <img
        src="https://raw.githubusercontent.com/bagrat/vim-buffet/e915a9f0627228c317a7498c800208813c0298c3/demo.png"
        alt="vim-buffet Screenshot"
    />
</h3>

Vim-buffet takes your buffers and tabs, and shows them combined in the
tabline. With this you always have your list of buffers visible, at the same
time not losing visibility into tabs. Moreover, `vim-buffet` provides handy
commands to boost navigation as well as a list of options to customize how the
tabline appears.

If you are new to the Vim world, then welcome, and start by learning Vim's
notions of [buffers, windows](http://vimdoc.sourceforge.net/htmldoc/windows.html)
and [tabpages](http://vimdoc.sourceforge.net/htmldoc/tabpage.html).

But if you are an experienced Vim user, you might have got tired of `bn/bp/ls/Ctrl-^`.

Take a look at the screenshot. The blue cuties are the tabpages. The tabpage
that has the buffers list coming next, is the current tabpage. The gray items
with names are the hidden/inactive buffers, and obviously, the green one is the
current buffer. The brighter items on both ends with the little arrows and numbers
are the truncation indicators. If all the buffers do not fit the screen,
`vim-buffet` truncates the tabline, and shows the number of truncated buffers on
both ends.

*__Note__: The instance of Vim in the screenshot is configured to use powerline
symbols and dev-icons. The default interface is only text and will work without
requiring any patched fonts. The default interface looks like in the screenshot
below.*

<h3 align="center">
    <img
        src="https://raw.githubusercontent.com/bagrat/vim-buffet/e915a9f0627228c317a7498c800208813c0298c3/demo2.png"
        alt="vim-buffet Screenshot"
    />
</h3>



## Installation

Use your favourite plugin manager to install `vim-buffet`. If you do not have any
preference or have not decided yet, I would recommend [Plug](https://github.com/junegunn/vim-plug).

```vim
Plug 'bagrat/vim-buffet'
```

After installation, `vim-buffet` is enabled by default, so whenever you restart
Vim, you will see the new tabline!



## Usage
### Commands

Apart from listing the buffers in the tabline, `vim-buffet` also provides some
handy commands to manipulate the buffers:

* `Bw[!]` -  wipe the current buffer without closing the window. If it has unsaved
  changes, an error will be shown, and the buffer will stay open. To ignore any
  changes and forcibly wipe the buffer, use `Bw!`.
* `Bonly[!]` - wipe all the buffers but the current one. If there are any buffers
  in the list that has unsaved changes, those will not be wiped. To ignore any
  changes and forcibly wipe all buffers except the current one, use `Bonly!`.

### Mappings

Mappings for switching buffers are also provided. You just need to add the following
mappings to your Vimrc file:

```vim
nmap <leader>1 <Plug>BuffetSwitch(1)
nmap <leader>2 <Plug>BuffetSwitch(2)
nmap <leader>3 <Plug>BuffetSwitch(3)
nmap <leader>4 <Plug>BuffetSwitch(4)
nmap <leader>5 <Plug>BuffetSwitch(5)
nmap <leader>6 <Plug>BuffetSwitch(6)
nmap <leader>7 <Plug>BuffetSwitch(7)
nmap <leader>8 <Plug>BuffetSwitch(8)
nmap <leader>9 <Plug>BuffetSwitch(9)
nmap <leader>0 <Plug>BuffetSwitch(10)
```

This will allow you to switch between buffers 1 - 10. You can get more `<Plug>`
mappings, or disable it completely, by configuring the `g:buffet_max_plug` option.

### Configuration

There are some configuration options that make it possible to customize how the
tabline works and looks like.

#### 🔩 Options

| Options | Default | Descriptions |
| --- | --- | --- |
| `g:buffet_always_show_tabline` | `1` | Set to `0`, the tabline will only be shown if there is more than one buffer or tab open |
| `g:buffet_powerline_separators` | `0` | Set to `1`, use powerline separators in between buffers and tabs in the tabline (see the first screenshot) |
| `g:buffet_separator` | `''` | The character to be used for separating items in the tabline |
| `g:buffet_show_index` | `0` | Set to `1`, show index before each buffer name. Index is useful for switching between buffers quickly |
| `g:buffet_max_plug` | `10` | The maximum number of `<Plug>BuffetSwitch` provided. Mapping will be disabled if the option is set to `0` |
| `g:buffet_use_devicons` | `1` | If set to `1` and [`vim-devicons`](https://github.com/ryanoasis/vim-devicons) plugin is installed, show file type icons for each buffer in the tabline. If the `vim-devicons` plugin is not present, the option will automatically default to `0` (*Note: you need to have `vim-devicons` loaded before `vim-buffet` in order to make this work*) |
| `g:buffet_tab_icon` | `'#'` | The character to be used as an icon for the tab items in the tabline |
| `g:buffet_new_buffer_name` | `'*'` | The character to be shown as the name of a new buffer |
| `g:buffet_modified_icon` | `'+'` | The character to be shown by the name of a modified buffer |
| `g:buffet_left_trun_icon` | `'<'` | The character to be shown by the count of truncated buffers on the left |
| `g:buffet_right_trun_icon` | `'>'` | The character to be shown by the count of truncated buffers on the right |
| `g:buffet_hidden_buffers` | `['terminal', 'quickfix']` | The types of buffers to hide from the tabline (*Note: This has the side effect of making all matching buffers unlisted)* |

#### 🎨 Colors
Of course, you can customize the colors of your tabline, to make it awesome and
yours. To get your custom colors set, define a function with name
`g:BuffetSetCustomColors` and place your highlight group definitions inside
the function.

```vim
" Note: Make sure the function is defined before `vim-buffet` is loaded.
function! g:BuffetSetCustomColors()
  hi! BuffetCurrentBuffer cterm=NONE ctermbg=5 ctermfg=8 guibg=#00FF00 guifg=#000000
endfunction
```

The following is the list of highlight groups, with self-explanatory
names:

| Highlights | Descriptions |
| --- | --- |
| `BuffetCurrentBuffer`    |  The current buffer.
| `BuffetActiveBuffer`     |  An active buffer (a non-current buffer visible in a non-current window) |
| `BuffetBuffer`           |  A non-current and non-active buffer.
| `BuffetModCurrentBuffer` |  The current buffer when modified.
| `BuffetModActiveBuffer`  |  A modified active buffer (a non-current buffer visible in a non-current window). |
| `BuffetModBuffer`        |  A modified non-current and non-active buffer.
| `BuffetTrunc`            |  The truncation indicator (count of truncated buffers  from the left or right) |
| `BuffetTab`              |  A tab |



## Recommendations

Here are some recommended mappings to boost your navigation experience:

```vim
noremap <Tab> :bn<CR>
noremap <S-Tab> :bp<CR>
noremap <Leader><Tab> :Bw<CR>
noremap <Leader><S-Tab> :Bw!<CR>
noremap <C-t> :tabnew split<CR>
```



## FAQ
<details><summary><b>How do I get the look like in the screenshot?</b></summary>
<p>

First you will need a patched font, extended with `powerline` and `font-awesome`
symbols. Also, you will need the
[`vim-devicons`](https://github.com/ryanoasis/vim-devicons) installed, which
also has great guides on how to patch fonts, as well as some pre-patched fonts.
As soon as you have the patched font, setting the following options, will give
you exactly the same tabline as you see in the first demo screenshot:

```vim
let g:buffet_powerline_separators = 1
let g:buffet_tab_icon = "\uf00a"
let g:buffet_left_trunc_icon = "\uf0a8"
let g:buffet_right_trunc_icon = "\uf0a9"
```

*Note: you need to have `vim-devicons` loaded before `vim-buffet` in order to
make this work.*
</p>
</details>


<details><summary><b>How to have the current buffer open in a new tab instead of a new one?</b></summary>
<p>

Just add this mapping to your Vimrc:

```vim
map <C-t> :tab split<CR>
```
</p>
</details>


<details><summary><b>I can only see the current active buffer in the tabline</b></summary>
<p>

The reason is that you probably use some statusline plugin (e.g. lightline,
airline) that also has tabline support, which overrides vim-buffet. All you need
to do is disable the tabline of the statusline plugin. 

#### For [lightline.vim](https://github.com/itchyny/lightline.vim)
It should be something like this:

```vim
let g:lightline.enable.tabline = 0
```

If that's not working, checkout this [issue](https://github.com/bagrat/vim-buffet/issues/20) especially this [comment](https://github.com/bagrat/vim-buffet/issues/20#issuecomment-706075930).
</p>
</details>



## Credits
<div>The icon in the header is made by <a href="https://www.flaticon.com/authors/freepik" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>



## License

See [LICENSE](https://github.com/bagrat/vim-buffet/blob/master/LICENS://github.com/bagrat/vim-buffet/blob/master/LICENSE).
