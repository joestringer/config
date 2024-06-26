set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" TODO: Figure out how to calm CoC down when there's no lsp
set tagfunc=CocTagFunc

map <C-s> :CocCommand document.showIncomingCalls<CR>
map <C-n> :CocCommand document.showOutgoingCalls<CR>

function! s:goto_tag(tagkind) abort
  let tagname = expand('<cWORD>')
  let winnr = winnr()
  let pos = getcurpos()
  let pos[0] = bufnr()

  if CocAction('jump' . a:tagkind)
    call settagstack(winnr, {
      \ 'curidx': gettagstack()['curidx'],
      \ 'items': [{'tagname': tagname, 'from': pos}]
      \ }, 't')
  endif
endfunction
nmap <C-]> :call <SID>goto_tag("Definition")<CR>
nmap gi :call <SID>goto_tag("Implementation")<CR>
nmap <C-[> :call <SID>goto_tag("References")<CR>

" use <tab> for trigger coc autocompletion and navigate to the next complete item
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

:inoremap <silent><expr> <C-Space>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<C-Space>" :
      \ coc#refresh()

lua require('litee.lib').setup({ tree = { icon_set = "nerd" }, panel = { orientation = "right", panel_size = 50 } })
lua require('litee.gh').setup({ icon_set = "nerd", map_resize_keys = true, keymaps = { expand = "<space>" }, })
"lua require('litee.gh').setup({ icon_set = "nerd", map_resize_keys = true, keymaps = { expand = "<space>" }, debug_logging = true, })

set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
"set foldlevel=1
set nofoldenable
" Nvim 0.8.0 inexplicably decided to turn mouse on by default and ignore vim
" configurations for the mouse setting. Defenestrate that heresy.
set mouse=

" Telescope-ui-select
" This is your opts table
lua require("telescope").setup { extensions = { ["ui-select"] = { require("telescope.themes").get_dropdown { } } } }
" To get ui-select loaded and working with telescope, you need to call
" load_extension, somewhere after setup function:
lua require("telescope").load_extension("ui-select")
"lua vim.lsp.buf.code_action()

lua require('nvim-dap-projects').search_project_config()
