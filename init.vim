:set number
:set relativenumber
:set autoindent
:set tabstop=4
:set shiftwidth=4
:set expandtab
:set softtabstop=4
:set mouse=a

call plug#begin()

Plug 'preservim/nerdtree' " File system explorer sidebar
Plug 'Xuyuanp/nerdtree-git-plugin' " Show git status icons in NerdTree
Plug 'ryanoasis/vim-devicons' " Using NerdFont compatible icons, used in NerdTree

Plug 'tpope/vim-commentary' " Easy commenting out lines
Plug 'preservim/tagbar' " Browse universal-ctags files 

Plug 'vim-airline/vim-airline' " Some statusline
Plug 'rafi/awesome-vim-colorschemes' " Color scheme selector

call plug#end()

" unset Continue with comment leader in next line
" found on https://superuser.com/questions/271023/can-i-disable-continuation-of-comments-to-the-next-line-in-vim
autocmd BufNewFile,BufRead * setlocal formatoptions-=cro

set encoding=UTF-8

nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>


" Start NERDTree. If a file is specified, move the cursor to its window.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * NERDTree | if argc() > 0 || exists("s:std_in") | wincmd p | endif


" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif


:colorscheme sonokai

" air-line
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

" airline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''


