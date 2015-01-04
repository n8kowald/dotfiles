set nocompatible   " stops vim from behaving in a vi compatible way

set tabstop=4		" how wide the tab is
set softtabstop=4	" num of spaces a tab counts for when <Tab> or <BS>
set shiftwidth=4	" spaces to use for autoindent
set autoindent		" copy indent from current line
set smartindent		" happy auto indenting
"set noexpandtab	" use tabs
set expandtab		" use spaces :*(

set ignorecase		" case-insensitive searching
set splitright		" place new split in the right hand side
set hlsearch		" highlight searched phrases.
set incsearch		" highlight as you search
set synmaxcol=512   " max characters Vim will highlight per line

filetype plugin indent on			" filetype detection
syntax on		" syntax highlighting on

" set the 't_Co' option in vim to 256 to override the terminfo value
"if &term == "xterm"
	set t_Co=256
"endif

colorscheme jellybeans

" Source the vimrc file after saving it
if has("autocmd")
	autocmd bufwritepost .vimrc source $MYVIMRC
endif

" toggle nice wrapping and movement mode
" taken from http://vim.wikia.com/wiki/VimTip38
" press "\w" to turn it on or off.
" by default, don't wrap:
set nowrap

" define the "\w" shortcut:
noremap <silent> <Leader>w :call ToggleWrap()<CR>

" define the function to toggle the wrapping:
function! ToggleWrap()
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

function! TabSpacesON()
	set list
		set listchars=tab:>.,trail:.,nbsp:.
		endfunction

function! TabSpacesOFF()
	set nolist
endfunction

nnoremap <f4> :call TabSpacesON()<cr>
nnoremap <f5> :call TabSpacesOFF()<cr>

function! s:VSetSearch()
	let temp = @@
	norm! gvy
	let @/ = '\V' . substitute(escape(@@, '\''), '\n', '\\n', 'g')
	let @@ = temp
endfunction

vnoremap * :<C-u>call <SID>VSetSearch()<CR>//<CR>
vnoremap # :<C-u>call <SID>VSetSearch()<CR>??<CR>

"set diffexpr=MyDiff()
function! MyDiff()
	let opt = '-a --binary '
	if &diffopt =~ 'icase' | let opt = opt . '-i ' | endif
	if &diffopt =~ 'iwhite' | let opt = opt . '-b ' | endif
	let arg1 = v:fname_in
	if arg1 =~ ' ' | let arg1 = '"' . arg1 . '"' | endif
	let arg2 = v:fname_new
	if arg2 =~ ' ' | let arg2 = '"' . arg2 . '"' | endif
	let arg3 = v:fname_out
	if arg3 =~ ' ' | let arg3 = '"' . arg3 . '"' | endif
	let eq = ''
	if $VIMRUNTIME =~ ' '
		if &sh =~ '\<cmd'
		let cmd = '""' . $VIMRUNTIME . '\diff"'
		let eq = '"'
		else
		let cmd = substitute($VIMRUNTIME, ' ', '" ', '''"') . '\diff"'
		endif
	else
		let cmd = $VIMRUNTIME . '\diff'
	endif
	silent execute '!' . cmd . ' ' . opt . arg1 . ' ' . arg2 . ' > ' . arg3 . eq
	endfunction

set laststatus=2

set statusline=\ %t\ [%{strlen(&fenc)?&fenc:'none'},%{&ff}]%h%m%r%y%=%c,%l/%L\ %P\
set statusline+=%#error#
set statusline+=%{StatuslineTrailingSpaceWarning()}
set statusline+=%*

"display a warning if &et is wrong, or we have mixed-indenting
set statusline+=%#error#
set statusline+=%{StatuslineTabWarning()}
set statusline+=%*\
"recalculate the tab warning flag when idle and after writing
autocmd cursorhold,bufwritepost * unlet! b:statusline_tab_warning
"return '[&et]' if &et is set wrong
"return '[mixed-indenting]' if spaces and tabs are used to indent
"return an empty string if everything is fine
function! StatuslineTabWarning()
	if !exists("b:statusline_tab_warning")
		let tabs = search('^\t', 'nw') != 0
		let spaces = search('^ ', 'nw') != 0
		if tabs && spaces
			let b:statusline_tab_warning =  '[mixed-indenting]'
		elseif (spaces && !&et) || (tabs && &et)
			let b:statusline_tab_warning = '[&et]'
		else
			let b:statusline_tab_warning = ''
		endif
	endif
	return b:statusline_tab_warning
endfunction


"recalculate the trailing whitespace warning when idle, and after saving
autocmd cursorhold,bufwritepost * unlet! b:statusline_trailing_space_warning

"return '[\s]' if trailing white space is detected
"return '' otherwise
function! StatuslineTrailingSpaceWarning()
	if !exists("b:statusline_trailing_space_warning")
		if search('\s\+$', 'nw') != 0
			let b:statusline_trailing_space_warning = '[\s]'
		else
			let b:statusline_trailing_space_warning = ''
		endif
	endif
	return b:statusline_trailing_space_warning
endfunction

" seek out ^[\t ] based on whether expandtabs (&et) is set
" no bells in this func. this means it's a little different to what
" the status msg from scrooloose shows. if your vim sets et
" then it will go to all ^\t, and all ^<space> when otherwise. IE
" it won't do this per file, but per your setting
function! SeekIndentWarningOccurrence()
	if (!&et)
		/^
	elseif (&et)
		/^\t
	endif
	exe "normal 0"
endfunction

function! SeekTrailingWhiteSpace()
	let [nws_line, nws_col] = searchpos('\s\+$', 'nw')
	if ( nws_line != 0 && nws_col != 0 )
		exe "normal ".nws_line."G"
		" This would be nicer, but | doesn't seem to collapse \t in to 1 col?
		" exe "normal ".nws_col."|"
		" so i'll do this instead :(  Might be a better way
		" this won't work if l has been mapped to something else
		exe "normal 0"
		exe "normal ".(nws_col-1)."l"
	endif
endfunction

nnoremap <f2> :call SeekTrailingWhiteSpace()<cr>
nnoremap <f3> :call SeekIndentWarningOccurrence()<cr>")"

"match ErrorMsg '\%>80v.\+'
match ErrorMsg '\%<81v.\%>80v'

if has("multi_byte")
  if &termencoding == ""
    let &termencoding = &encoding
  endif
  set encoding=utf-8
  setglobal fileencoding=utf-8
  "setglobal bomb
  set fileencodings=ucs-bom,utf-8,latin1
endif

" Changes plugin
:let g:changes_vcs_check=1
:let g:changes_vcs_system='svn'
":let g:changes_autocmd=1

" NERDTree plugin
:let g:NERDTreeDirArrows=0

" Disable syntastic
"let g:pathogen_disabled = ['syntastic']
let g:syntastic_enable_signs=1
let g:syntastic_check_on_open=1
let g:syntastic_mode_map = { 'mode': 'active', 'passive_filetypes': ['css', 'java'] }

" Tell vim where the tags file lives
:set tags=/var/www/tags
:set tags+=/usr/share/php/Zend/tags

call pathogen#infect()
