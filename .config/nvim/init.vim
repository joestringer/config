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

require ('nvim-treesitter.configs').setup({
  -- A list of parser names, or "all" (the five listed parsers should always be installed)
  ensure_installed = { "c", "go", "lua", "vim", "vimdoc" },
})

-- vim.lsp.buf.code_action()
local dap, dapui = require("dap"),require("dapui")
dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end
dapui.setup()
vim.fn.sign_define('DapBreakpoint',{ text ='🟥', texthl ='', linehl ='', numhl =''})
vim.fn.sign_define('DapStopped',{ text ='▶️', texthl ='', linehl ='', numhl =''})
require('nvim-dap-projects').search_project_config()

local wk = require('which-key')
wk.add(
    {
        "<leader>d", group = "Debug",
        { "<leader>dt", function() require("dapui").toggle() end, desc = "Toggle dap-ui" },
        { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Set Breakpoint" },
        { "<leader>dn", function() require("dap").step_over() end, desc = "Step Over" },
        { "<leader>dj", function() require("dap").step_into() end, desc = "Step Into" },
        { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
    },
    {
        "<leader>gh", group = "GitHub",
        { "<leader>ghpt", desc = "<cmd>GHOpenToPR<cr>" },
        { "<leader>ghpe", desc = "<cmd>GHExpandPR<cr>" },
        { "<leader>ghpp", desc = "<cmd>GHPopOutPR<cr>" },
    },
    {
        "<leader>ghi", group = "Issues",
        { "<leader>ghip", desc = "<cmd>GHPreviewIssue<cr>" },
    },
    {
        "<leader>ght", group = "Threads",
        { "<leader>ghtc", desc = "<cmd>GHCreateThread<cr>" },
        { "<leader>ghtn", desc = "<cmd>GHNextThread<cr>" },
        { "<leader>ghtt", desc = "<cmd>GHToggleThread<cr>" },
    },
    {
        "<leader>ghr", group = "Review",
        { "<leader>ghrb", desc = "<cmd>GHStartReview<cr>" },
        { "<leader>ghre", desc = "<cmd>GHExpandReview<cr>" },
        { "<leader>ghrz", desc = "<cmd>GHCollapseReview<cr>" },
        { "<leader>ghrd", desc = "<cmd>GHDeleteReview<cr>" },
        { "<leader>ghrc", desc = "<cmd>GHCloseReview<cr>" },
        { "<leader>ghrs", desc = "<cmd>GHSubmitReview<cr>" },
    },
    {
        "<leader>ghc", group = "Commits",
        { "<leader>ghco", desc = "<cmd>GHOpenToCommit<cr>" },
        { "<leader>ghce", desc = "<cmd>GHExpandCommit<cr>" },
        { "<leader>ghcc", desc = "<cmd>GHCloseCommit<cr>" },
        { "<leader>ghcp", desc = "<cmd>GHPopOutCommit<cr>" },
        { "<leader>ghcz", desc = "<cmd>GHCollapseCommit<cr>" }
    },
    {
        "<leader>ghp", group = "Pull Request",
        { "<leader>ghpo", desc = "<cmd>GHOpenPR<cr>" },
        { "<leader>ghpd", desc = "<cmd>GHPRDetails<cr>" },
        { "<leader>ghpr", desc = "<cmd>GHRefreshPR<cr>" },
        { "<leader>ghpz", desc = "<cmd>GHCollapsePR<cr>" },
        { "<leader>ghpc", desc = "<cmd>GHClosePR<cr>" },
    },
    {
        "<leader>ghl", group = "Litee",
        { "<leader>ghlt", desc = "<cmd>LTPanel<cr>" },
    }
)
END_LUA
