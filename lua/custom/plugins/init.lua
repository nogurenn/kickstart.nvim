-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- vim.opt.tabstop = 4
-- vim.opt.shiftwidth = 4
-- vim.softtabstop = 4

-- Center cursor after returning to tag
vim.keymap.set('n', '<C-t>', '<C-t>zz', { desc = 'Return to tag and center cursor' })

vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down half page and center cursor' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up half page and center cursor' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Move to next search result and center cursor' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Move to previous search result and center cursor' })
vim.keymap.set('x', '<leader>p', '"_dP', { desc = 'Paste and return to that same register/yank' })
-- Move highlighted line / block of text in visual mode
vim.keymap.set('x', 'J', ":move '>+1<CR>gv=gv", { desc = 'Move highlighted block down' })
vim.keymap.set('x', 'K', ":move '<-2<CR>gv=gv", { desc = 'Move highlighted block up' })
-- Append line below without moving cursor
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Append line below without moving cursor' })

require('custom.plugins.telescope.multigrep').setup()

-- For gopls, we need to use `textDocument/codeAction` to organize imports
-- https://github.com/neovim/nvim-lspconfig/issues/115
local golang_organize_imports = function(bufnr, isPreflight)
  local params = vim.lsp.util.make_range_params(nil, vim.lsp.util._get_offset_encoding(bufnr))
  params.context = { only = { 'source.organizeImports' } }

  -- buf_request_sync defaults to a 1000ms timeout. Depending on your
  -- machine and codebase, you may want longer. Add an additional
  -- argument after params if you find that you have to write the file
  -- twice for changes to be saved.
  -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
  local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params)
  for cid, res in pairs(result or {}) do
    for _, r in pairs(res.result or {}) do
      if r.edit then
        local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or 'utf-16'
        vim.lsp.util.apply_workspace_edit(r.edit, enc)
      end
    end
  end
  vim.lsp.buf.format { async = false }
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('LspFormatting', {}),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client.name == 'gopls' then
      -- hack: Preflight async request to gopls, which can prevent blocking when save buffer on first time opened
      golang_organize_imports(bufnr, true)

      vim.api.nvim_create_autocmd('BufWritePre', {
        pattern = '*.go',
        group = vim.api.nvim_create_augroup('LspGolangOrganizeImports.' .. bufnr, {}),
        callback = function()
          golang_organize_imports(bufnr)
        end,
      })
    end
  end,
})

return {
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
    opts = {},
  },
  {
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter', -- Lazy load when entering insert mode
    config = function()
      require('copilot').setup {
        suggestion = {
          enabled = true,
          auto_trigger = true, -- Automatically trigger suggestions
          debounce = 75, -- Debounce time in ms
          keymap = {
            accept = '<C-J>', -- Keybinding to accept a suggestion
            accept_line = '<M-l>', -- Keybinding to accept a whole line
            accept_word = '<M-j>', -- Keybinding to accept a whole word
            next = '<M-]>',
            prev = '<M-[>',
            dismiss = '<C-]>',
          },
        },
        panel = {
          enabled = true,
          layout = {
            position = 'bottom', -- Display panel at the bottom
            ratio = 0.4, -- Height ratio
          },
        },
        filetypes = {
          go = true,
          python = true,
          javascript = true,
          typescript = true,
          lua = true,
          yaml = true,
          markdown = true,
          help = false,
          gitcommit = true,
          gitrebase = true,
          hgcommit = true,
          ['*'] = false, -- Disable by default for all filetypes
        },
      }
    end,
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'zbirenbaum/copilot.vim' }, -- or zbirenbaum/copilot.lua
      { 'nvim-lua/plenary.nvim', branch = 'master' }, -- for curl, log and async functions
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    opts = {
      -- See Configuration section for options
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
}
