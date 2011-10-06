set tabstop=4
set shiftwidth=4
set expandtab
set ignorecase
syntax on
set shiftround
set autoindent
set smartindent
set ic
" toggle nice wrapping and movement mode
" taken from http://vim.wikia.com/wiki/VimTip38
" press "\w" to turn it on or off.
" by default, don't wrap:
set nowrap
" define the "\w" shortcut:
noremap <silent> <Leader>w :call ToggleWrap()<CR>
" define the function to toggle the wrapping:
function ToggleWrap()
 if &wrap
  echo "Wrap OFF"
  setlocal nowrap
  set virtualedit=all
  silent! nunmap <buffer> <Up>
  silent! nunmap <buffer> <Down>
  silent! nunmap <buffer> <Home>
  silent! nunmap <buffer> <End>
  silent! iunmap <buffer> <Up>
  silent! iunmap <buffer> <Down>
  silent! iunmap <buffer> <Home>
  silent! iunmap <buffer> <End>
 else
  echo "Wrap ON"
  setlocal wrap linebreak nolist
  set virtualedit=
  setlocal display+=lastline
  noremap  <buffer> <silent> <Up>   gk
  noremap  <buffer> <silent> <Down> gj
  noremap  <buffer> <silent> <Home> g<Home>
  noremap  <buffer> <silent> <End>  g<End>
  inoremap <buffer> <silent> <Up>   <C-o>gk
  inoremap <buffer> <silent> <Down> <C-o>gj
  inoremap <buffer> <silent> <Home> <C-o>g<Home>
  inoremap <buffer> <silent> <End>  <C-o>g<End>
 endif
endfunction

