// Powers interactive tab widgets (such as the translation style preview)
// using semantic ARIA tabs, keyboard arrow navigation, and find-in-page sync.
(() => {
  const initTabs = (root) => {
    const list = root.querySelector('[role="tablist"]');
    const tabs = [...list.querySelectorAll('[role="tab"]')];
    const panels = [...root.querySelectorAll('[role="tabpanel"]')];
    if (!tabs.length || tabs.length !== panels.length) return;

    const select = (index, moveFocus) => {
      tabs.forEach((tab, i) => {
        const active = i === index;
        tab.setAttribute('aria-selected', String(active));
        tab.tabIndex = active ? 0 : -1;
        tab.toggleAttribute('focusgroupstart', active);
        const panel = panels[i];
        if (active) {
          panel.hidden = false;
          panel.tabIndex = 0;
        } else {
          panel.hidden = 'until-found';
          panel.removeAttribute('tabindex');
        }
      });
      const current = tabs[index];
      if (moveFocus) current.focus();
      current.scrollIntoView({ block: 'nearest', inline: 'nearest', container: 'nearest' });
    };

    tabs.forEach((tab, i) => {
      tab.addEventListener('click', () => select(i, false));
      tab.addEventListener('keydown', (e) => {
        let next = -1;
        if (e.key === 'ArrowRight') next = (i + 1) % tabs.length;
        else if (e.key === 'ArrowLeft') next = (i - 1 + tabs.length) % tabs.length;
        else if (e.key === 'Home') next = 0;
        else if (e.key === 'End') next = tabs.length - 1;
        if (next === -1) return;
        e.preventDefault();
        select(next, true);
      });
    });

    panels.forEach((panel, i) => {
      panel.addEventListener('beforematch', () => select(i, false));
    });
  };

  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.tabs').forEach(initTabs);
  });
})();
