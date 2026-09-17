(() => {
  const directChildList = (li) =>
    Array.from(li.children).find((child) => child.tagName === "UL") || null;

  const directRow = (li) => {
    for (const child of li.children) {
      if (child.classList?.contains("file-tree-row")) return child;
      if (child.tagName === "P") {
        const row = Array.from(child.children).find((node) =>
          node.classList?.contains("file-tree-row")
        );
        if (row) return row;
      }
    }
    return null;
  };

  const setState = (row, list, expanded) => {
    const value = expanded ? "true" : "false";
    row.dataset.fileTreeExpanded = value;
    row.setAttribute("aria-expanded", value);
    list.hidden = !expanded;

    const button = row.querySelector(":scope > .file-tree-toggle-button");
    if (button) {
      const name = row.dataset.fileTreeName || "folder";
      button.setAttribute("aria-expanded", value);
      button.setAttribute(
        "aria-label",
        `${expanded ? "Collapse" : "Expand"} ${name}`
      );
      button.title = expanded ? "Collapse folder" : "Expand folder";
    }
  };

  const initialiseTree = (tree) => {
    tree.querySelectorAll("li").forEach((li) => {
      const list = directChildList(li);
      const row = directRow(li);
      if (!list || !row || row.dataset.fileTreeToggle !== "true") return;
      if (row.dataset.fileTreeReady === "true") return;

      row.dataset.fileTreeReady = "true";
      row.classList.add("file-tree-folder-interactive");

      const button = document.createElement("button");
      button.type = "button";
      button.className = "file-tree-toggle-button";
      button.setAttribute("aria-controls", "");
      row.insertBefore(button, row.firstChild);

      const expanded = row.dataset.fileTreeExpanded !== "false";
      setState(row, list, expanded);

      const toggle = () => {
        setState(row, list, row.getAttribute("aria-expanded") !== "true");
      };

      button.addEventListener("click", (event) => {
        event.preventDefault();
        event.stopPropagation();
        toggle();
      });

      row.addEventListener("click", (event) => {
        if (event.target.closest("a, .file-tree-info, .file-tree-toggle-button")) return;
        toggle();
      });
    });
  };

  const initialise = () => {
    document.querySelectorAll(".semantic-file-tree").forEach(initialiseTree);
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialise, { once: true });
  } else {
    initialise();
  }
})();
