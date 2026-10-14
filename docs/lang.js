// Sends browsers set to Japanese from an English page to its ja.html, unless
// English was picked with the language link. The choice is kept apart from the
// web app's EN / JA switch so the app keeps following the browser by default.
(() => {
  const key = 'langria-page-language';
  let choice = '';
  try { choice = localStorage.getItem(key) || ''; } catch {}
  const japanese = choice ? choice === 'ja' : /^ja\b/i.test(navigator.language || '');
  if (document.documentElement.lang === 'en' && japanese) { location.replace('ja.html' + location.search + location.hash); return; }
  document.addEventListener('click', (event) => {
    const link = event.target.closest?.('nav a[lang]');
    if (link) try { localStorage.setItem(key, link.lang); } catch {}
  });
})();
