set nocompatible    " vim, not vi.. must be first, because it changes other options as a side effect

set background=dark
set modeline
syntax on
colorscheme onedark

set laststatus=2   " Always show the statusline
set statusline=%M%h%y\ %t\ %F\ %p%%\ %l/%L\ %=[%{&ff},%{&ft}]\ [a=\%03.3b]\ [h=\%02.2B]\ [%l,%v]
set title titlelen=150 titlestring=%(\ %M%)%(\ (%{expand(\"%:p:h\")})%)%(\ %a%)\ -\ %{v:servername}

set nowrap

set backspace=indent,eol,start  " backspace over all kinds of things

set cmdheight=1         " command line two lines high
set complete=.,w,b,u,U,t,i,d  " do lots of scanning on tab completion
set cursorline
highlight CursorLine gui=underline cterm=underline " show the cursor line

set enc=utf-8 fenc=utf-8 tenc=utf-8   " utf-8 encoding
set ffs=unix,dos,mac       " default fileformats

set history=3000        " keep 3000 lines of command line history
"set maxmem=25123  " 24 MB -  max mem in Kbyte to use for one buffer.  Max is 2000000

set noautowrite         " don't automagically write on :next

set showcmd         " Show us the command we're typing
set showfulltag       " show full completion tags

set listchars=tab:>.,trail:.,extends:#,nbsp:. " Highlight problematic whitespace

set cindent
set smartindent
set autoindent
set tabstop=8
set shiftwidth=8
set cinkeys=0{,0},:,0#,!^F
set smarttab
set noexpandtab
set list

" Go language settings for taglist.vim
let s:tlist_def_go_settings = 'go;g:enum;s:struct;u:union;t:type;' .
                           \ 'v:variable;f:function'

autocmd FocusGained * :redraw!

" Don't expand tabs for Makefiles
augroup UseTabsForMakefiles
    autocmd!
    autocmd FileType make setlocal noexpandtab
    au FileType tex,plaintex set tabstop=8
    au FileType tex,plaintex set shiftwidth=8
augroup END

set gdefault " substitutions apply to entire lines by default
set nojoinspaces " Don't double-space between sentences

nnoremap ; :
let mapleader=","

" Remove the Windows ^M - when the encodings gets messed up
noremap <Leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

if has("autocmd")
    filetype on
    filetype indent on
    filetype plugin on
endif

set pastetoggle=<F2>
map <F7> :setlocal spell! spelllang=en_nz<CR>

let g:formatoptions = 'off'
function! ToggleAutoWrap()
    if g:formatoptions  == 'off'
        set formatoptions+=a
        let g:formatoptions = 'on'
        echo "autowrap=on"
    else
        set formatoptions-=a
        let g:formatoptions = 'off'
        echo "autowrap=off"
    endif
endfunction
map <F10> :call ToggleAutoWrap()<CR>

let g:taboptions = 'off'
function! ToggleTabsToSpaces()
    if g:taboptions == 'off'
        set nolist
        set expandtab
        set shiftwidth=4
        let g:taboptions = 'on'
        echo "expandtab=on"
    else
        set list
        set noexpandtab
        set shiftwidth=8
        let g:taboptions = 'off'
        echo "expandtab=off"
    endif
endfunction
map <F8> :call ToggleTabsToSpaces()<CR>

function! SetTabs()
    if g:taboptions == 'on'
        call ToggleTabsToSpaces()
    endif
endfunction

function! ClearTabs()
    if g:taboptions == 'off'
        call ToggleTabsToSpaces()
    endif
endfunction

function! RunCscope()
    let l:cscope_tests = confirm('Do you want cscope to index test files?', "&Yes\n&No", 2)
    silent !make tags 2>&1 >/dev/null
    \ || find . -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.go" > cscope.files
    \ && ctags -L cscope.files
    \ && cscope -R -q -b 2>&1 >/dev/null
    " Dropped from the above..
    "\ && sed -i '/.*\/vendor\//d' cscope.files
    if l:cscope_tests != 1
        silent !sed -i '/.*_test.go$/d' cscope.files
        silent !rm -f cscope.*out
        silent !cscope -R -q -b 2>&1 >/dev/null
    endif
    silent cs reset
    redraw!
endfunction
map <F12> :call RunCscope()<CR>

" Highlight characters past column 80
augroup HighlightLongLines
    if version >= 703
      set cc=80
      highlight ColorColumn ctermbg=0 guibg=black
    elseif version >= 702
      :autocmd!
      :au BufWinEnter * let w:m1=matchadd('Search', '\%<81v.\%>77v', -1)
      :au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
    else
      :match ErrorMsg '\%>80v.\+'
    endif
augroup END

highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$\| \+\ze\t/
augroup WSHighlight
    autocmd!
    autocmd BufWinEnter * match ExtraWhitespace /\s\+$\| \+\ze\t/
    autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
    autocmd InsertLeave * match ExtraWhitespace /\s\+$\| \+\ze\t/
    autocmd BufWinLeave * call clearmatches()
augroup END

" Return to last edit position when opening files (You want this!)
augroup ReturnLastEdited
    autocmd!
    autocmd BufReadPost *
         \ if line("'\"") > 0 && line("'\"") <= line("$") |
         \   exe "normal! g`\"" |
         \ endif
augroup END

func! CleanupWS()
  exe "normal mz"
  %s/\s\+$//ge
  exe "normal `z"
endfunc

augroup git
    autocmd!
    autocmd Filetype gitcommit setlocal spell textwidth=72
    " Don't return to last edit position for git commits
    au FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])
augroup END

augroup ft_latex
    autocmd!
    au FileType tex,plaintex au BufWinEnter * call clearmatches()
    au FileType tex,plaintex au BufReadPre,FileReadPre * call ClearTabs()
    "au BufReadPre,FileReadPre *.tex call ClearTabs()
    au FileType tex,plaintex set tabstop=4
    au FileType tex,plaintex set shiftwidth=4
augroup END

augroup ft_yaml
    autocmd!
    au FileType yaml au BufReadPre,FileReadPre * call ClearTabs()
    au FileType yaml set tabstop=2
    au FileType yaml set shiftwidth=2
    au FileType yaml set cursorcolumn
augroup END

augroup zip
    autocmd!
    au BufEnter *.gz %!gunzip
augroup END

func! GoFmt()
    !gofmt -w -s %
    !goimports -w %
    e!
endfunc

augroup ft_go
    autocmd!
    au FileType go au BufReadPre,FileReadPre * call SetTabs()
    au FileType go set tabstop=8
    au FileType go set shiftwidth=8
    au BufWritePost *.go call GoFmt()
augroup END


func! PyFmt()
    !autopep8 --in-place --aggressive --aggressive %
    e!
endfunc

augroup ft_py
    autocmd!
    au FileType py au BufReadPre,FileReadPre * call ClearTabs()
    au FileType py set tabstop=4
    au FileType py set shiftwidth=4
    au BufWritePost *.py call PyFmt()
augroup END


" Plugin management
call plug#begin('~/.vim/bundle')
Plug 'airblade/vim-gitgutter'
Plug 'benmills/vimux'
Plug 'edkolev/tmuxline.vim'
"Plug 'hari-rangarajan/CCTree'
Plug 'inkarkat/vim-AutoAdapt'
Plug 'inkarkat/vim-ingo-library'
Plug 'joestringer/cscope_maps'
Plug 'joestringer/sonicpi.vim'
Plug 'junegunn/limelight.vim'
Plug 'jjo/vim-cue', {'for': 'cue'}
Plug 'ldelossa/litee.nvim' ", { 'do': 'litee.nvim#setup' }
Plug 'ldelossa/gh.nvim' ", { 'do': 'litee.gh#setup' }
Plug 'ldelossa/nvim-dap-projects', {'for': 'go'}
Plug 'mfussenegger/nvim-dap'
Plug 'neoclide/coc.nvim', {'branch': 'release', 'for': ['c', 'go', 'json', 'markdown', 'sh', 'vim'] }
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim' " TODO: Check if this enables fzf
Plug 'nvim-telescope/telescope-ui-select.nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
"Plug 'neovim/nvim-lspconfig'
Plug 'rcarriga/nvim-dap-ui'
Plug 'scrooloose/nerdtree'
Plug 'sebdah/vim-delve', {'for': 'go'}
Plug 'stsewd/sphinx.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'thinca/vim-localrc'
Plug 'towolf/vim-helm'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline'
Plug 'vim-scripts/taglist.vim'
call plug#end()

" GitGutter
let g:gitgutter_enabled = 0
noremap <F5> :GitGutterToggle<CR>
nmap <F3> <Plug>(GitGutterPrevHunk)
nmap <F4> <Plug>(GitGutterNextHunk)

" Airline
let g:airline_powerline_fonts = 1
let g:airline#extensions#whitespace#mixed_indent_algo = 2 " spaces after indent
set t_Co=256
" tabline at top of window
let g:airline#themes#molokai#palette = {}
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#buffer_nr_show = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'
let g:airline#extensions#tabline#show_close_button = 0
let g:airline#extensions#tabline#buffer_min_count = 2
" fixes unneccessary redraw, when e.g. opening Gundo window
let airline#extensions#tabline#ignore_bufadd_pat =
            \ '\c\vgundo|undotree|vimfiler|tagbar|nerd_tree'

" Syntastic
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_aggregate_errors = 1
let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [],'passive_filetypes': [] }
map <F6> :call SyntasticCheck()<CR>:call SyntasticToggleMode()<CR>

let g:mouse = 'off'
function! ToggleMouse()
    if g:mouse  == 'off'
        set mouse=a
        let g:mouse = 'on'
        echo "mouse=auto"
    else
        set mouse=
        let g:mouse = 'off'
        echo "mouse=off"
    endif
endfunction
map <F9> :call ToggleMouse()<CR>

" NERDtree
" auto-close if NERDtree is the last window open
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" ^n for toggling
map <C-n> :NERDTreeToggle<CR>

" Delve
let g:delve_new_command = 'new'
let g:delve_use_vimux = 1

" Cscope maps
nmap <Leader>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <Leader>s :scs find s <C-R>=expand("<cword>")<CR><CR>
nmap <Leader>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <Leader>d :scs find d <C-R>=expand("<cword>")<CR><CR>

" Configure AutoAdapt rules to only apply to certain copyrights
let s:copyrightText = 'Copyright:\?\%(\s\+\%((C)\|&copy;\|\%xa9\)\)\?\s\+\zs'
let s:copyrightFrom = '\%('' . strftime("%Y") . ''\)\@!\d\{4}'
let s:copyrightTo   = '\ze\k\@![^-]\|\(-\%('' . strftime("%Y") . ''\)\@!\d\{4}\)'
let s:copyrightPattern = '%(Cilium\|Isovalent\|Joe Stringer)\zs'
let g:AutoAdapt_Rules = [
    \   {
    \       'name': 'Copyright notice',
    \       'patternexpr': '''\c\<' . s:copyrightText . '\(' . s:copyrightFrom . '\)\%(' . s:copyrightTo . '\>\)\(\s*' . s:copyrightPattern . '\)''',
    \       'replacement': '\=submatch(1) . "-" . strftime("%Y")'
    \   },
    \ ]

" Window navigation
nmap <C-Up> :wincmd k<CR>
nmap <C-Down> :wincmd j<CR>
nmap <C-Left> :wincmd h<CR>
nmap <C-Right> :wincmd l<CR>

" Window resize
nmap <C-S-Up> <C-w>10+<CR>
nmap <C-S-Down> <C-w>10-<CR>

"Use 24-bit (true-color) mode in Vim/Neovim when outside tmux.
if (has("nvim"))
  "For Neovim 0.1.3 and 0.1.4 < https://github.com/neovim/neovim/pull/2198 >
  let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif
"For Neovim > 0.1.5 and Vim > patch 7.4.1799 < https://github.com/vim/vim/commit/61be73bb0f965a895bfb064ea3e55476ac175162 >
"Based on Vim patch 7.4.1770 (`guicolors` option) < https://github.com/vim/vim/commit/8a633e3427b47286869aa4b96f2bfc1fe65b25cd >
" < https://github.com/neovim/neovim/wiki/Following-HEAD#20160511 >
if (has("termguicolors"))
  set termguicolors
endif

" Debug coc.nvim crashes and failures
"let g:node_client_debug = 1
"let $NODE_CLIENT_LOG_FILE = '/tmp/coc-logfile'
