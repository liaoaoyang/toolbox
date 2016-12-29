"Vim
set nocompatible
filetype plugin indent on
set nu
set ai
colorscheme molokai
syntax on
set ts=4
set backspace=2
set fileencodings=ucs-bom,utf-8,cp936,gb18030,big5,euc-jp,euc-kr,latin1
set t_Co=256

"Key map
let mapleader=","
map <F12> <ESC>:tabn<CR> "Tab
imap <F12> <ESC>:tabn<CR>
map <F11> <ESC>:tabp<CR>
imap <F11> <ESC>:tabp<CR>
map <F10> <ESC>:tabnew<CR>
imap <F10> <ESC>:tabnew<CR>

imap <C-\> <ESC>

map <F2> <ESC>:NERDTree<CR> "NERDTree
imap <F2> <ESC>:NERDTree<CR>

map <F4> <ESC>:q<CR> "Quit
imap <F4> <ESC>:q<CR>

map <F3> <ESC>:TagbarToggle<CR> "TagBar
imap <F3> <ESC>:TagbarToggle<CR>

map <leader>t <ESC>:set paste<CR>
map <leader>tt <ESC>:set nopaste<CR>
imap <leader>t <ESC>:set paste<CR>
imap <leader>tt <ESC>:set nopaste<CR>

"Vundle
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()
Bundle 'gmarik/vundle'
Bundle 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
Bundle 'tomasr/molokai'
Bundle 'vim-scripts/Tagbar'
Bundle 'vim-scripts/The-NERD-tree'
"Bundle 'Valloric/YouCompleteMe'

"Powerline
set laststatus=2
let g:Powerline_symbols = 'fancy'
set guifont=Monaco\ for\ Powerline

"TagBar

"Airline

"YCM
"let g:ycm_global_ycm_extra_conf = "~/.vim/.ycm_extra_conf.py"
"nnoremap <leader>gg :YcmCompleter GoToDefinitionElseDeclaration<CR>
"nnoremap <leader>hh :YcmCompleter GoToInclude<CR>
"map <leader>bb <C-o>

