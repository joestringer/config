set nocompatible    " vim, not vi.. must be first, because it changes other options as a side effect

set background=dark
set modeline

set laststatus=2   " Always show the statusline
set statusline=%M%h%y\ %t\ %F\ %p%%\ %l/%L\ %=[%{&ff},%{&ft}]\ [a=\%03.3b]\ [h=\%02.2B]\ [%l,%v]
set title titlelen=150 titlestring=%(\ %M%)%(\ (%{expand(\"%:p:h\")})%)%(\ %a%)\ -\ %{v:servername}

set nowrap

set backspace=indent,eol,start  " backspace over all kinds of things

set cmdheight=1         " command line two lines high
set complete=.,w,b,u,U,t,i,d  " do lots of scanning on tab completion
set cursorline          " show the cursor line

set enc=utf-8 fenc=utf-8   " utf-8 encoding
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
set shiftwidth=4
set cinkeys=0{,0},:,0#,!^F
set smarttab
set expandtab

set gdefault " substitutions apply to entire lines by default
set nojoinspaces " Don't double-space between sentences

set cscopetag

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

" Don't expand tabs for Makefiles
autocmd FileType make setlocal noexpandtab

let g:taboptions = 'on'
function! ToggleTabsToSpaces()
    if g:taboptions == 'off'
        set expandtab
        let g:taboptions = 'on'
        echo "expandtab=on"
    else
        set noexpandtab
        let g:taboptions = 'off'
        echo "expandtab=off"
    endif
endfunction
map <F8> :call ToggleTabsToSpaces()<CR>

function! RunCscope()
    silent !cscope -R -b 2>&1 >/dev/null
    silent !ctags -R 2>&1 >/dev/null
    silent cs reset
    redraw!
endfunction
map <F9> :call RunCscope()<CR>

nnoremap ; :

" Remove the Windows ^M - when the encodings gets messed up
noremap <Leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

if has("autocmd")
    filetype on
    filetype indent on
    filetype plugin on
endif

" Highlight characters past column 80
if version >= 703
  set cc=80
elseif version >= 702
  :au BufWinEnter * let w:m1=matchadd('Search', '\%<81v.\%>77v', -1)
  :au BufWinEnter * let w:m2=matchadd('ErrorMsg', '\%>80v.\+', -1)
else
  :match ErrorMsg '\%>80v.\+'
endif
syntax on

highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$\| \+\ze\t/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$\| \+\ze\t/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$\| \+\ze\t/
autocmd BufWinLeave * call clearmatches()

" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

func! CleanupWS()
  exe "normal mz"
  %s/\s\+$//ge
  exe "normal `z"
endfunc

" Don't return to last edit position for git commits
au FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])
autocmd Filetype gitcommit setlocal spell textwidth=72

au FileType tex,plaintex let g:miniBufExplVSplit = 20
au FileType tex,plaintex au BufWinEnter * call clearmatches()

" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    en
    return ''
endfunction

" MinibufExplorer options
let g:miniBufExplModSelTarget = 1
let g:miniBufExplMapCTabSwitchBufs = 1

" Svndiff()
hi DiffAdd      ctermfg=0 ctermbg=2 guibg='green'
hi DiffDelete   ctermfg=0 ctermbg=1 guibg='red'
hi DiffChange   ctermfg=0 ctermbg=3 guibg='yellow'
noremap <F3> :call Svndiff("prev")<CR>
noremap <F4> :call Svndiff("next")<CR>
noremap <F5> :call Svndiff("clear")<CR>
