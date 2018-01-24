// Configure CodeMirror Keymap
require([
  'nbextensions/vim_binding/vim_binding',   // depends your installation
], function() {


  CodeMirror.Vim.defineOperator("comment_op", function(cm) {
    cm.toggleComment();
  });
  CodeMirror.Vim.mapCommand("gc", "operator", "comment_op", {});

  CodeMirror.Vim.map(';', ':');

  CodeMirror.Vim.map("<C-a>", "ggVG", "normal");

  CodeMirror.Vim.mapCommand(",<Space>", "action", "noh", {}, {context: "normal"});

  //  Insert New line
  CodeMirror.Vim.map("U", "o<Esc>", "normal");

  CodeMirror.Vim.map("<c-l>", "<Esc>A", "insert");

  CodeMirror.Vim.map(",c<Space>", "i<c-/><Esc>", "normal");

  CodeMirror.Vim.map("rL",   "v$pgvy");
  CodeMirror.Vim.map("riw",  "viwp");
  CodeMirror.Vim.map("riW",  "viWp");
  // CodeMirror.Vim.map("ri\"", "vi\"pgvy");
  // CodeMirror.Vim.map("ri'",  "vi'pgvy");
  CodeMirror.Vim.map("rl",   "vpgvy");
  CodeMirror.Vim.map("rr",   "Vpgvy");

  //  Quicker navigation
  CodeMirror.Vim.map("H", "^", "normal");
  CodeMirror.Vim.map("L", "$", "normal");

  // Swap j/k and gj/gk (Note that <Plug> mappings)
  CodeMirror.Vim.map("j", "<Plug>(vim-binding-gj)", "normal");
  CodeMirror.Vim.map("k", "<Plug>(vim-binding-gk)", "normal");
  CodeMirror.Vim.map("gj", "<Plug>(vim-binding-j)", "normal");
  CodeMirror.Vim.map("gk", "<Plug>(vim-binding-k)", "normal");
});

require([
  'nbextensions/vim_binding/vim_binding',
  'base/js/namespace',
], function(vim_binding, ns) {

  // Add post callback
  vim_binding.on_ready_callbacks.push(function(){
    var km = ns.keyboard_manager;
    // Indicate the key combination to run the commands
    km.edit_shortcuts.add_shortcut('ctrl-s', 'jupyter-notebook:save-notebook', true);

    km.edit_shortcuts.add_shortcut('ctrl-k', 'jupyter-notebook:restart-kernel-and-run-all-cells', true);

    // Update Help
    km.edit_shortcuts.events.trigger('rebuild.QuickHelp');
  });
});

require([
	'base/js/namespace',
	'codemirror/keymap/vim',
	'nbextensions/vim_binding/vim_binding'
], function(ns) {

  CodeMirror.Vim.defineAction("hello", function(){
		ns.notebook.command_mode();
		ns.notebook.focus_cell();
    ns.keyboard_manager.actions.call('jupyter-notebook:run-cell');
  });
  // ',' is the key you map the action to
  CodeMirror.Vim.mapCommand(",", "action", "hello", {}, {context: "normal"});
});
