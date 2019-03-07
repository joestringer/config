set nocompatible    " vim, not vi.. must be first, because it changes other options as a side effect

set background=dark
set modeline
syntax on

set laststatus=2   " Always show the statusline
set statusline=%M%h%y\ %t\ %F\ %p%%\ %l/%L\ %=[%{&ff},%{&ft}]\ [a=\%03.3b]\ [h=\%02.2B]\ [%l,%v]
set title titlelen=150 titlestring=%(\ %M%)%(\ (%{expand(\"%:p:h\")})%)%(\ %a%)\ -\ %{v:servername}

set nowrap

set backspace=indent,eol,start  " backspace over all kinds of things

set cmdheight=1         " command line two lines high
set complete=.,w,b,u,U,t,i,d  " do lots of scanning on tab completion
set cursorline          " show the cursor line

set enc=utf-8 fenc=utf-8 tenc=utf-8   " utf-8 encoding
set ffs=unix,dos,mac       " default fileformats

set history=3000        " keep 3000 lines of command line history
set maxmem=25123  " 24 MB -  max mem in Kbyte to use for one buffer.  Max is 2000000

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

" Stop the accidental opening of help when mashing ESC
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

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
    if l:cscope_tests != 1
        silent !sed -i '/.*_test.go$/d' cscope.files
        silent !rm cscope.*out
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
augroup END

augroup zip
    autocmd!
    au BufEnter *.gz %!gunzip
augroup END

func! GoFmt()
    !gofmt -w %
    e!
endfunc

augroup ft_go
    autocmd!
    au FileType go au BufReadPre,FileReadPre * call SetTabs()
    au FileType go set tabstop=8
    au FileType go set shiftwidth=8
    au BufWritePost *.go call GoFmt()
augroup END

" Pathogen
execute pathogen#infect()

" MinibufExplorer options
let g:miniBufExplModSelTarget = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplHideWhenDiff = 1
let g:miniBufExplMaxSize = 3

" GitGutter
let g:gitgutter_enabled = 0
noremap <F5> :GitGutterToggle<CR>
nmap <F3> <Plug>GitGutterPrevHunk
nmap <F4> <Plug>GitGutterNextHunk

" Airline
let g:airline_powerline_fonts = 1
let g:airline#extensions#whitespace#mixed_indent_algo = 2 " spaces after indent
set t_Co=256

" Syntastic
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_aggregate_errors = 1
let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [],'passive_filetypes': [] }
map <F6> :call SyntasticCheck()<CR>:call SyntasticToggleMode()<CR>

" Cscope maps
nmap <Leader>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <Leader>s :scs find s <C-R>=expand("<cword>")<CR><CR>
nmap <Leader>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <Leader>d :scs find d <C-R>=expand("<cword>")<CR><CR>
