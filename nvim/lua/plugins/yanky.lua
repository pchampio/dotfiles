---@module 'lazy'
---@type LazySpec
return {
  'gbprod/yanky.nvim',
  event = 'CursorHold',
  config = function()
    vim.cmd [[hi YankyPut guifg=#37afd3 gui=underline,bold]]
    require('yanky').setup {
      system_clipboard = { sync_with_ring = true },
      ring = { storage = 'memory', ignore_registers = { "+", "_", "*", "\"" } },
      picker = {},
      highlight = {
        on_put = true,
        on_yank = false,
        timer = 500,
      },
    }
    vim.keymap.set({ 'n', 'x' }, '<leader>P', function() Snacks.picker.yanky() end, { desc = 'Open Yank History' })

    -- Upper Y yank to system clipboard
    vim.keymap.set('n', 'YY', '"+yy', { silent = true, noremap = true, desc = "  Copy Line System" })
    vim.keymap.set('', 'Y', '"+y', { silent = true, noremap = true, desc = "  Copy System" })

    vim.keymap.set('n', '[y', '<Plug>(YankyCycleForward)', { desc = '󰳺  Yank Cycle Backward', silent = true })
    vim.keymap.set('n', ']y', '<Plug>(YankyCycleBackward)', { desc = '󰳸  Yank Cycle Forward', silent = true })
    vim.keymap.set('n', '[Y', '<Plug>(YankyCycleBackward)', { desc = '_󰳸  Yank Cycle Forward', silent = true })
    vim.keymap.set('n', ']Y', '<Plug>(YankyCycleForward)', { desc = '_󰳺  Yank Cycle Backward', silent = true })
    vim.keymap.set('n', 'p', '<Plug>(YankyPutAfter)', { desc = 'Paste after' })
    vim.keymap.set('n', 'P', '<Plug>(YankyPutBefore)', { desc = 'Paste before' })
    vim.keymap.set('n', 'gp', '<Plug>(YankyPutIndentAfterLinewise)', { desc = '󰱖  paste Line Under' })
    vim.keymap.set('n', 'gP', '<Plug>(YankyPutIndentBeforeLinewise)', { desc = '󰱘  Paste Line Above' })


    -- Tmux / System clipboard integration yanks to '*' which can double or make
    -- empty entries in the yank history. With the above yanky.ring.ignore_registers
    -- config and this autocmd, we intercept the yank and manually add it to the
    -- yanky history after filtering.
    vim.api.nvim_create_autocmd("TextYankPost", {
      pattern = "*",
      callback = function()
        local copied_content = vim.fn.getreg("\"")
        if #vim.trim(copied_content) >= 1 then
          require("yanky.history").push({
            regcontents = copied_content,
            regtype = "y",
          })
        end
      end,
    })

    -- Modify default Snacks yanky picker behavior to set the enter as set_default_register instead of directly pasting
    -- Snacks.picker.sources.yanky.actions.confirm = Snacks.picker.sources.yanky.actions.set_default_register
  end,
}
