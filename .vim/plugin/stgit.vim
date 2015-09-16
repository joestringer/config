" Vim filetype detection plugin
" Language:     StGit commit messages
" Author:       Zane Bitter <zane.bitter@alliedtelesis.co.nz>
"

if exists('g:loaded_stgit') || &cp
  finish
endif
let g:loaded_stgit = 1

if has("autocmd")
  augroup stgit
    autocmd!

    " Detect 'stg new' files
    autocmd BufNewFile,BufRead .stgit-new.txt       setf     stgnew
    autocmd BufNewFile,BufRead .stgit-new.txt       setlocal filetype=stgnew
    autocmd BufNewFile,BufRead .stgitmsg.txt        setf     stgnew
    autocmd BufNewFile,BufRead .stgitmsg.txt        setlocal filetype=stgnew
    " Ignore the modeline so we get type 'stgnew' instead of 'diff'
    autocmd BufNewFile,BufRead .stgitmsg.txt        setlocal nomodeline

    " Detect 'stg edit' files
    autocmd BufNewFile,BufRead .stgit-edit.txt      setf     stgedit
    autocmd BufNewFile,BufRead .stgit-edit.txt      setlocal filetype=stgedit
    " Use set filetype instead of setfiletype to override detection as patch
    autocmd BufNewFile,BufRead .stgit-edit.patch    setlocal filetype=stgedit
    autocmd BufNewFile,BufRead .stgit-edit.diff     setlocal filetype=stgedit
    autocmd BufNewFile,BufRead .stgit-failed.patch  setlocal filetype=stgedit

    " Detect 'stg squash' files
    autocmd BufNewFile,BufRead .stgit-squash.txt    setf     stgsquash
    autocmd BufNewFile,BufRead .stgit-squash.txt    setlocal filetype=stgsquash

    " Detect 'stg mail' files
    autocmd BufNewFile,BufRead .stgitmail.txt       setf     stgmail
    autocmd BufNewFile,BufRead .stgitmail.txt       setlocal filetype=stgmail


    " A modeline in a diff belongs to the diffed file, so ignore it
    autocmd BufNewFile,BufRead .stgit-edit.patch    setlocal nomodeline
    autocmd BufNewFile,BufRead .stgit-edit.diff     setlocal nomodeline
    autocmd BufNewFile,BufRead .stgit-failed.patch  setlocal nomodeline
    autocmd BufNewFile,BufRead .stgitmail.txt       setlocal nomodeline


    " Set parameters on 'stg new' files to be consistent with the modeline
    autocmd FileType           stgnew               setlocal textwidth=72
    autocmd FileType           stgnew               setlocal nobackup

    " For other stg files set textwidth the same as 'stg new'
    autocmd FileType           stgedit              setlocal textwidth=72
    autocmd FileType           stgmail              setlocal textwidth=72
    autocmd FileType           stgsquash            setlocal textwidth=72

  augroup END
endif " has("autocmd")
