set nocompatible    " vim, not vi.. must be first, because it changes other options as a side effect

set background=dark
set modeline

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
set paste               " don't indent blocks of pasted text

set showcmd         " Show us the command we're typing
set showfulltag       " show full completion tags

set listchars=tab:>.,trail:.,extends:#,nbsp:. " Highlight problematic whitespace

set cindent
set smartindent
set autoindent
set expandtab
set tabstop=2
set shiftwidth=4
set cinkeys=0{,0},:,0#,!^F
set smarttab

map cw <esc>:cw<cr>
map cn <esc>:cn<cr>
map cp <esc>:cp<cr>

" Remove the Windows ^M - when the encodings gets messed up
noremap <Leader>m mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm

" Use jk for exiting to normal mode
imap jk <ESC>

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

" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    en
    return ''
endfunction
