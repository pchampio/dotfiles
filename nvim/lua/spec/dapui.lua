local M = {
  'rcarriga/nvim-dap-ui',
  dependencies = {
    {
      'mfussenegger/nvim-dap',
      'nvim-neotest/nvim-nio',
    },
  },
  config = function()
    local dap, dapui = require 'dap', require 'dapui'

    dapui.setup()

    dap.listeners.after.event_initialized['dapui_config'] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated['dapui_config'] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited['dapui_config'] = function()
      dapui.close()
    end

    vim.keymap.set({ 'n', 'v' }, '<M-e>', function()
      require('dapui').eval()
    end, { desc = 'DAP: evaluate expression' })

    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        -- provide the absolute path for `codelldb` command if not using the one installed using `mason.nvim`
        command = 'codelldb',
        args = { '--port', '${port}' },
      },
    }
    dap.configurations.c = {
      {
        name = 'Launch file',
        type = 'codelldb',
        request = 'launch',
        program = function()
          local path
          vim.ui.input({
            prompt = 'Path to executable: ',
            default = vim.uv.cwd() .. '/build/',
          }, function(input)
            path = input
          end)
          vim.cmd [[redraw]]
          return path
        end,
        cwd = '${workspaceFolder}',
        args = function()
          local args_string = vim.fn.input 'Arguments: '
          return vim.split(args_string, ' ')
        end,
        stopOnEntry = false,
      },
    }
    dap.configurations.cpp = dap.configurations.c

    vim.keymap.set('n', '<F5>', function()
      dap.continue()
    end, { desc = 'DAP: continue' })
    vim.keymap.set('n', '<F10>', function()
      dap.step_over()
    end, { desc = 'DAP: step over' })
    vim.keymap.set('n', '<F11>', function()
      dap.step_into()
    end, { desc = 'DAP: step into' })
    vim.keymap.set('n', '<F12>', function()
      dap.step_out()
    end, { desc = 'DAP: step out' })
    vim.keymap.set('n', '<s-F5>', function()
      dap.disconnect { terminateDebuggee = true }
      dap.close()
      dapui.close()
    end, { desc = 'DAP: stop' })
    vim.keymap.set('n', '<Leader>b', function()
      dap.toggle_breakpoint()
    end, { desc = 'DAP: toggle breakpoint' })
    vim.keymap.set('n', '<Leader>B', function()
      dap.set_breakpoint()
    end, { desc = 'DAP: set breakpoint' })
    vim.keymap.set('n', '<Leader>cp', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'DAP: set condiitional breakpoint' })
    vim.keymap.set('n', '<Leader>lp', function()
      dap.set_breakpoint(nil, nil, vim.fn.input 'Log point message: ')
    end, { desc = 'DAP: set log point' })
    vim.keymap.set('n', '<Leader>dr', function()
      dap.repl.open()
    end, { desc = 'DAP: open RELP' })
    vim.keymap.set('n', '<Leader>dl', function()
      dap.run_last()
    end, { desc = 'DAP: run last' })

    local widgets = require 'dap.ui.widgets'
    vim.keymap.set({ 'n', 'v' }, '<Leader>dh', function()
      widgets.hover()
    end, { desc = 'DAP: hover' })
    vim.keymap.set({ 'n', 'v' }, '<Leader>dp', function()
      widgets.preview()
    end, { desc = 'DAP: preview' })
    vim.keymap.set('n', '<Leader>df', function()
      widgets.centered_float(widgets.frames)
    end, {
      desc = 'DAP: view the current frame in a centered floating window',
    })
    vim.keymap.set(
      'n',
      '<Leader>ds',
      function()
        widgets.centered_float(widgets.scopes)
      end,
      { desc = 'DAP: view the current scopes in a centered floating window' }
    )

    vim.api.nvim_set_hl(
      0,
      'DapBreakpoint',
      { ctermbg = 0, fg = '#ab4444', bg = '#31353f' }
    )
    vim.api.nvim_set_hl(
      0,
      'DapLogPoint',
      { ctermbg = 0, fg = '#61afef', bg = '#31353f' }
    )
    vim.api.nvim_set_hl(
      0,
      'DapStopped',
      { ctermbg = 0, fg = '#98c379', bg = '#31353f' }
    )
    vim.api.nvim_set_hl(0, 'DapLine', { ctermbg = 0, bg = '#31353f' })

    vim.fn.sign_define('DapBreakpoint', {
      text = '',
      texthl = 'DapBreakpoint',
      linehl = 'DapLine',
      numhl = 'DapBreakpoint',
    })
    vim.fn.sign_define('DapBreakpointCondition', {
      text = '',
      texthl = 'DapBreakpoint',
      linehl = 'DapLine',
      numhl = 'DapBreakpoint',
    })
    vim.fn.sign_define('DapLogPoint', {
      text = '󰜋',
      texthl = 'DapLogPoint',
      linehl = 'DapLine',
      numhl = 'DapLogPoint',
    })
    vim.fn.sign_define('DapStopped', {
      text = '',
      texthl = 'DapStopped',
      linehl = 'DapStopped',
      numhl = 'DapStopped',
    })
    vim.fn.sign_define('DapBreakpointRejected', {
      text = '',
      texthl = 'DapBreakpoint',
      linehl = 'DapBreakpoint',
      numhl = 'DapBreakpoint',
    })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'dap-repl' },
      callback = function()
        vim.opt_local.colorcolumn = ''
      end,
    })
  end,
}

return M
