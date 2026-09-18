(() => {
  let nextTreeId = 0;

  function directChildList(row) {
    const li = row.closest("li");
    if (!li) return null;
    return Array.from(li.children).find((el) => el.tagName === "UL" || el.tagName === "OL") || null;
  }

  function setState(row, expanded) {
    const list = directChildList(row);
    const button = row.querySelector(":scope > .tree-toggle");
    if (!list || !button) return;

    if (!list.id) {
      nextTreeId += 1;
      list.id = `qsc-tree-children-${nextTreeId}`;
    }

    const value = expanded ? "true" : "false";
    list.hidden = !expanded;
    row.dataset.treeExpanded = value;
    row.setAttribute("aria-expanded", value);
    button.setAttribute("aria-expanded", value);
    button.setAttribute("aria-controls", list.id);

    const label = row.dataset.treeLabel || "branch";
    button.setAttribute("aria-label", `${expanded ? "Collapse" : "Expand"} ${label}`);
  }

  function init(root) {
    root.querySelectorAll('.tree-row[data-tree-toggle="true"]').forEach((row) => {
      if (row.dataset.treeReady === "true") return;
      row.dataset.treeReady = "true";

      const button = row.querySelector(":scope > .tree-toggle");
      if (!button) return;

      setState(row, row.dataset.treeExpanded !== "false");

      button.addEventListener("click", (event) => {
        event.preventDefault();
        event.stopPropagation();
        setState(row, row.dataset.treeExpanded === "false");
      });
    });
  }

  function initialise() {
    document.querySelectorAll(".semantic-tree").forEach(init);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialise, { once: true });
  } else {
    initialise();
  }
})();
