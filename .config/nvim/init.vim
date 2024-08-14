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

" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" use <tab> for trigger coc autocompletion and navigate to the next complete item
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction

:inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ CheckBackspace() ? "\<TAB>" :
      \ coc#refresh()

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice.
inoremap <silent><expr> <CR> pumvisible() ? pumconfirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
"set foldlevel=1
set nofoldenable
" Nvim 0.8.0 inexplicably decided to turn mouse on by default and ignore vim
" configurations for the mouse setting. Defenestrate that heresy.
set mouse=

set timeout
set timeoutlen=150

" Configure lua plugins for the remainder of the config file.
lua <<END_LUA

require('mini.icons').setup()
require('litee.lib').setup({
	tree = {
		icon_set = "nerd"
	},
	panel = {
		orientation = "right",
		panel_size = 50,
	},
})
require('litee.gh').setup({
	-- debug_logging = true,
	icon_set = "nerd",
	map_resize_keys = true,
	keymaps = {
		expand = "t"
	},
})

-- Telescope-ui-select
-- This is your opts table
require("telescope").setup {
	extensions = {
		["ui-select"] = {
			require("telescope.themes").get_dropdown { }
		}
	}
}

-- To get ui-select loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require("telescope").load_extension("ui-select")

-- vim.lsp.buf.code_action()
require('nvim-dap-projects').search_project_config()

local wk = require('which-key')
wk.register({
    g = {
        name = "+Git",
        h = {
            name = "+Github",
            c = {
                name = "+Commits",
                c = { "<cmd>GHCloseCommit<cr>", "Close" },
                e = { "<cmd>GHExpandCommit<cr>", "Expand" },
                o = { "<cmd>GHOpenToCommit<cr>", "Open To" },
                p = { "<cmd>GHPopOutCommit<cr>", "Pop Out" },
                z = { "<cmd>GHCollapseCommit<cr>", "Collapse" },
            },
            i = {
                name = "+Issues",
                p = { "<cmd>GHPreviewIssue<cr>", "Preview" },
            },
            l = {
                name = "+Litee",
                t = { "<cmd>LTPanel<cr>", "Toggle Panel" },
            },
            r = {
                name = "+Review",
                b = { "<cmd>GHStartReview<cr>", "Begin" },
                c = { "<cmd>GHCloseReview<cr>", "Close" },
                d = { "<cmd>GHDeleteReview<cr>", "Delete" },
                e = { "<cmd>GHExpandReview<cr>", "Expand" },
                s = { "<cmd>GHSubmitReview<cr>", "Submit" },
                z = { "<cmd>GHCollapseReview<cr>", "Collapse" },
            },
            p = {
                name = "+Pull Request",
                c = { "<cmd>GHClosePR<cr>", "Close" },
                d = { "<cmd>GHPRDetails<cr>", "Details" },
                e = { "<cmd>GHExpandPR<cr>", "Expand" },
                o = { "<cmd>GHOpenPR<cr>", "Open" },
                p = { "<cmd>GHPopOutPR<cr>", "PopOut" },
                r = { "<cmd>GHRefreshPR<cr>", "Refresh" },
                t = { "<cmd>GHOpenToPR<cr>", "Open To" },
                z = { "<cmd>GHCollapsePR<cr>", "Collapse" },
            },
            t = {
                name = "+Threads",
                c = { "<cmd>GHCreateThread<cr>", "Create" },
                n = { "<cmd>GHNextThread<cr>", "Next" },
                t = { "<cmd>GHToggleThread<cr>", "Toggle" },
            },
        },
    },
}, { prefix = "<leader>" })
END_LUA
