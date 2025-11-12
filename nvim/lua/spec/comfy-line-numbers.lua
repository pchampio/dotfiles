return {
  -- show line number with only left side(1~5) number to convenient manipulate
  'mluders/comfy-line-numbers.nvim',
  event = 'BufReadPost',
  opts = {
    labels = {
      '', '1', '', '2', '', '3', '', '4', '', '5', '', '11', '', '12', '', '13', '', '14', '', '15', '', '21', '', '22', '', '23', '', '24', '', '25', '', '31', '', '32', '', '33', '', '34', '', '35', '', '41', '', '42', '', '43', '', '44', '', '45', '', '51', '', '52', '', '53', '', '54', '', '55', '', '111', '', '112', '', '113', '', '114', '', '115', '', '121', '', '122', '', '123', '', '124', '', '125'
    },
    hidden_file_types = {
      'dashboard',
      'help',
      'gitcommit',
      'undotree',
    }
  }
}
