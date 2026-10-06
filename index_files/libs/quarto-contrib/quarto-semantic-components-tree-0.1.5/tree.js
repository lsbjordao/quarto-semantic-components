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

  function branchRows(root) {
    return Array.from(root.querySelectorAll('.tree-row[data-tree-toggle="true"]'));
  }

  function branchDepth(root, row) {
    const li = row.closest("li");
    if (!li) return 0;

    let depth = 0;
    let current = li.parentElement;
    while (current && current !== root) {
      if (current.tagName === "UL" || current.tagName === "OL") depth += 1;
      current = current.parentElement;
    }
    return depth;
  }

  function setRows(rows, expanded) {
    rows.forEach((row) => setState(row, expanded));
  }

  function makeButton(className, label, textContent, onClick) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = className;
    button.setAttribute("aria-label", label);
    button.title = label;
    button.textContent = textContent;
    button.addEventListener("click", (event) => {
      event.preventDefault();
      event.stopPropagation();
      onClick();
    });
    return button;
  }

  function initControls(root) {
    if (root.dataset.treeControls !== "true" || root.dataset.treeControlsReady === "true") return;
    root.dataset.treeControlsReady = "true";

    const rows = branchRows(root);
    if (!rows.length) return;

    const panel = document.createElement("div");
    panel.className = "tree-controls";
    panel.setAttribute("role", "group");
    panel.setAttribute("aria-label", "Tree controls");

    const global = document.createElement("div");
    global.className = "tree-controls-global";
    global.append(
      makeButton("tree-control tree-control-all", "Expand all", "Expand all", () => setRows(rows, true)),
      makeButton("tree-control tree-control-all", "Collapse all", "Collapse all", () => setRows(rows, false))
    );
    panel.appendChild(global);

    const byDepth = new Map();
    rows.forEach((row) => {
      const depth = branchDepth(root, row);
      if (!byDepth.has(depth)) byDepth.set(depth, []);
      byDepth.get(depth).push(row);
    });

    const levels = document.createElement("div");
    levels.className = "tree-controls-levels";
    levels.setAttribute("aria-label", "Controls by tree level");

    Array.from(byDepth.keys()).sort((a, b) => a - b).forEach((depth) => {
      const group = document.createElement("span");
      group.className = "tree-control-level";
      group.setAttribute("role", "group");
      group.setAttribute("aria-label", `Level ${depth}`);

      const label = document.createElement("span");
      label.className = "tree-control-level-label";
      label.textContent = `L${depth}`;
      group.append(
        label,
        makeButton("tree-control tree-control-icon", `Expand level ${depth}`, "＋", () => setRows(byDepth.get(depth), true)),
        makeButton("tree-control tree-control-icon", `Collapse level ${depth}`, "−", () => setRows(byDepth.get(depth), false))
      );
      levels.appendChild(group);
    });

    panel.appendChild(levels);
    root.prepend(panel);
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

    initControls(root);
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
