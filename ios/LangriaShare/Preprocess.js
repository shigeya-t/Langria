// Run by Safari in the page when "Langria" is picked from the share button
// (NSExtensionJavaScriptPreprocessingFile). Hands the extension the selected
// text, or the page's main text when nothing is selected; the extension
// translates at most the first 5,000 characters (ShareViewController.swift).
var ExtensionPreprocessingJS = {
  run: function (args) {
    var selection = String(window.getSelection ? window.getSelection() : '').trim();
    var text = '', self = ExtensionPreprocessingJS;
    if (!selection && document.body) {
      var root = document.querySelector('article') || document.querySelector('main') || document.querySelector('[role="main"]') || self.densest() || document.body;
      text = self.clean(root.innerText);
      // The headline often sits outside the story's element.
      var heading = document.querySelector('h1');
      var title = heading && !root.contains(heading) ? self.clean(heading.innerText) : '';
      if (title && text.indexOf(title) !== 0) text = title + '\n\n' + text;
      text = text.slice(0, 20000);
    }
    args.completionFunction({ selection: selection, text: text });
  },
  // Many news sites have no <article> or <main>, and their body starts with
  // long lists of menu links, which leave no room for the story within the
  // 5,000 characters and which models tend to send back untranslated. The
  // story is usually the element whose paragraphs hold the most text, link
  // text aside (scored like Readability: a block's own text counts for it and
  // for its parent).
  densest: function () {
    var skip = /^(A|SCRIPT|STYLE|NOSCRIPT|NAV|HEADER|FOOTER|ASIDE|BUTTON|SELECT|OPTION|LABEL|FORM)$/;
    var scores = new Map();
    var add = function (element, length) { if (element) scores.set(element, (scores.get(element) || 0) + length); };
    var ownText = function (element) {
      var length = 0;
      for (var node = element.firstChild; node; node = node.nextSibling) {
        if (node.nodeType === 3) length += node.nodeValue.replace(/\s+/g, '').length;
        else if (node.nodeType === 1 && /^(B|STRONG|I|EM|SPAN|FONT|SUB|SUP|MARK|SMALL|BR)$/.test(node.tagName)) length += ownText(node);
      }
      return length;
    };
    var elements = document.body ? document.body.getElementsByTagName('*') : [];
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      if (skip.test(element.tagName) || element.closest('a, nav, header, footer, aside')) continue;
      var length = ownText(element);
      if (length < 25) continue;
      add(element, length);
      add(element.parentElement, length);
    }
    var best = null, bestScore = 0;
    scores.forEach(function (score, element) { if (score > bestScore) { best = element; bestScore = score; } });
    return bestScore >= 200 ? best : null;
  },
  clean: function (text) {
    return String(text || '').replace(/[ \t]+\n/g, '\n').replace(/\n{3,}/g, '\n\n').trim();
  },
  finalize: function () {}
};
