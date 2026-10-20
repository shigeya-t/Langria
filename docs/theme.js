// Applies the light / dark theme picked with the header button before the page
// is drawn, and follows the system setting until one is picked. The choice is
// kept apart from the web app's theme so the app keeps following the system.
(() => {
  const key = 'langria-page-theme';
  const root = document.documentElement;
  const current = () => root.dataset.theme || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  const apply = (theme) => {
    root.dataset.theme = theme;
    const button = document.getElementById('themeToggle');
    if (button) button.setAttribute('aria-pressed', theme === 'dark');
  };
  let stored = '';
  try { stored = localStorage.getItem(key) || ''; } catch {}
  if (stored === 'light' || stored === 'dark') root.dataset.theme = stored;
  document.addEventListener('DOMContentLoaded', () => {
    const button = document.getElementById('themeToggle');
    if (!button) return;
    button.hidden = false;
    button.setAttribute('aria-pressed', current() === 'dark');
    button.addEventListener('click', () => {
      const next = current() === 'dark' ? 'light' : 'dark';
      try { localStorage.setItem(key, next); } catch {}
      apply(next);
    });
  });
})();
