// Run by Safari in the page when "Langria" is picked from the share button
// (NSExtensionJavaScriptPreprocessingFile). Hands the extension the selected
// text, or the page's main text when nothing is selected; the extension
// translates at most the first 5,000 characters (ShareViewController.swift).
var ExtensionPreprocessingJS = {
  run: function (args) {
    var selection = String(window.getSelection ? window.getSelection() : '').trim();
    var text = '';
    if (!selection) {
      var root = document.querySelector('article') || document.querySelector('main') || document.querySelector('[role="main"]') || document.body;
      text = root ? String(root.innerText || '').replace(/[ \t]+\n/g, '\n').replace(/\n{3,}/g, '\n\n').trim().slice(0, 20000) : '';
    }
    args.completionFunction({ selection: selection, text: text });
  },
  finalize: function () {}
};
