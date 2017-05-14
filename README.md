# VimWorkspace - Manage your buffers and tabs with ease

If you are an experienced Vim user, you might got tired of `bn/bp/ls/Ctrl-^`. If
you are new to the Vim world, then welcome, and start by learning Vim's
notions of [buffers, windows](http://vimdoc.sourceforge.net/htmldoc/windows.html)
and [tabpages](http://vimdoc.sourceforge.net/htmldoc/tabpage.html).

VimWorkspace brings the IDE-like tabs into Vim, for easy navigation, and a nice,
customizable look.

## Introduction

VimWorkspace takes your buffers and tabs, and shows them combined in the
tabline. With this you always have your list of buffers visible, at the same
time not losing visibility into tabs. Moreover, VimWorkspace provides handy
commands to boost navigation as well as a list of options to customize how the
tabline appears. See the following sections for information about each of those.

## Installation

Use your favourite plugin manager to install VimWorkspace. If you do not have any
preference or have not decided yet, I would recommend [Plug](https://github.com/junegunn/vim-plug).

```
Plug 'bagrat/vim-workspace'
```

After installation, VimWorkspace is enabled by default, so whenever you restart
Vim, you will see the new tabline!

## Commands

As already mentioned, VimWorkflow provides a set of commands to easily navigate
through your buffers. You might wonder, how would some commands replace `:bn`
and `:bp`. The answer is, that if you are using some other plugins, that add
their buffers to your buffer list, you might not want to be switched to
those, while navigating through your list. VimWorkflow does this for you, and
also provides options to extend the list of buffers to be ignored.

* `WSNext` - switch to the buffer to the right of current one
* `WSPrev` - switch to the buffer to the left of current one
* `WSClose[!]` -  close the current buffer. If is has unsaved changes, an error
  will be shown, and the buffer will stay open. To ignore any changes and
  forcibly close the buffer, use `WSClose!`.
* `WSTabNew` - create a new tab. This uses the current buffer to load into the
  new tab's window, to avoid having a new empty buffer created. This is
  basically and equivalent of `tabedit <current-buffer>`.
* `WSBufOnly` - close all the buffers but the current.
