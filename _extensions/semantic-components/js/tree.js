(() => {
  function directChildList(row) {
    const li = row.closest('li');
    if (!li) return null;
    return Array.from(li.children).find((el) => el.tagName === 'UL' || el.tagName === 'OL') || null;
  }
  function setState(row, expanded) {
    const list = directChildList(row);
    const button = row.querySelector(':scope > .tree-toggle');
    if (!list || !button) return;
    list.hidden = !expanded;
    row.dataset.treeExpanded = expanded ? 'true' : 'false';
    row.setAttribute('aria-expanded', expanded ? 'true' : 'false');
    button.setAttribute('aria-expanded', expanded ? 'true' : 'false');
    const label = row.dataset.treeLabel || 'branch';
    button.setAttribute('aria-label', (expanded ? 'Collapse ' : 'Expand ') + label);
  }
  function init(root) {
    root.querySelectorAll('.tree-row[data-tree-toggle="true"]').forEach((row) => {
      setState(row, row.dataset.treeExpanded !== 'false');
      const button = row.querySelector(':scope > .tree-toggle');
      if (!button) return;
      button.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();
        setState(row, row.dataset.treeExpanded === 'false');
      });
    });
  }
  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.semantic-tree').forEach(init);
  });
})();
