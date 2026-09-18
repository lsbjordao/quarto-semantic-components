(() => {
  const SVG_NS = "http://www.w3.org/2000/svg";
  const MOBILE_BREAKPOINT = 700;

  function clamp(value, min, max) {
    return Math.min(max, Math.max(min, value));
  }

  function curveValue(root) {
    const parsed = Number.parseFloat(root.dataset.roadmapCurve || "0.6");
    return Number.isFinite(parsed) ? clamp(parsed, 0, 1) : 0.6;
  }

  function ensureSvg(root) {
    let svg = root.querySelector(":scope > .roadmap-svg");
    if (svg) return svg;

    svg = document.createElementNS(SVG_NS, "svg");
    svg.classList.add("roadmap-svg");
    svg.setAttribute("aria-hidden", "true");
    svg.setAttribute("preserveAspectRatio", "none");

    const bed = document.createElementNS(SVG_NS, "path");
    bed.classList.add("roadmap-road-bed");
    const road = document.createElementNS(SVG_NS, "path");
    road.classList.add("roadmap-road");
    svg.append(bed, road);
    root.prepend(svg);
    return svg;
  }

  function catmullRomPath(points) {
    if (points.length < 2) return "";
    if (points.length === 2) {
      const [a, b] = points;
      const dx = (b.x - a.x) * 0.45;
      return `M ${a.x.toFixed(2)} ${a.y.toFixed(2)} C ${(a.x + dx).toFixed(2)} ${a.y.toFixed(2)}, ${(b.x - dx).toFixed(2)} ${b.y.toFixed(2)}, ${b.x.toFixed(2)} ${b.y.toFixed(2)}`;
    }

    let path = `M ${points[0].x.toFixed(2)} ${points[0].y.toFixed(2)}`;
    for (let i = 0; i < points.length - 1; i += 1) {
      const p0 = points[i - 1] || points[i];
      const p1 = points[i];
      const p2 = points[i + 1];
      const p3 = points[i + 2] || p2;
      const c1x = p1.x + (p2.x - p0.x) / 6;
      const c1y = p1.y + (p2.y - p0.y) / 6;
      const c2x = p2.x - (p3.x - p1.x) / 6;
      const c2y = p2.y - (p3.y - p1.y) / 6;
      path += ` C ${c1x.toFixed(2)} ${c1y.toFixed(2)}, ${c2x.toFixed(2)} ${c2y.toFixed(2)}, ${p2.x.toFixed(2)} ${p2.y.toFixed(2)}`;
    }
    return path;
  }

  function effectiveOrientation(root) {
    const requested = root.dataset.roadmapOrientation === "vertical" ? "vertical" : "horizontal";
    if (requested === "vertical") return "vertical";
    return root.clientWidth <= MOBILE_BREAKPOINT ? "vertical" : "horizontal";
  }

  function setHorizontalGeometry(root, items, curve) {
    const maxCardHeight = items.reduce((max, item) => {
      const card = item.querySelector(":scope > .roadmap-card");
      return Math.max(max, card ? card.getBoundingClientRect().height : 0);
    }, 0);
    const amplitude = 54 * curve;
    const requiredHeight = Math.max(320, maxCardHeight * 2 + amplitude * 2 + 88);
    root.style.setProperty("--roadmap-horizontal-height", `${requiredHeight.toFixed(2)}px`);

    items.forEach((item, index) => {
      const wave = Math.sin(index * (Math.PI / 2) - Math.PI / 2) * amplitude;
      item.style.setProperty("--roadmap-wave-y", `${wave.toFixed(2)}px`);
      item.style.removeProperty("--roadmap-wave-x");
    });
  }

  function setVerticalGeometry(root, items, curve) {
    root.style.removeProperty("--roadmap-horizontal-height");
    const amplitude = Math.min(18, Math.max(8, root.clientWidth * 0.03)) * curve;
    items.forEach((item, index) => {
      const wave = Math.sin(index * (Math.PI / 2) - Math.PI / 2) * amplitude;
      item.style.setProperty("--roadmap-wave-x", `${wave.toFixed(2)}px`);
      item.style.removeProperty("--roadmap-wave-y");
    });
  }

  function markerPoints(root, items) {
    const rootRect = root.getBoundingClientRect();
    return items
      .map((item) => {
        const marker = item.querySelector(":scope > .roadmap-marker");
        if (!marker) return null;
        const rect = marker.getBoundingClientRect();
        return {
          x: rect.left - rootRect.left + rect.width / 2,
          y: rect.top - rootRect.top + rect.height / 2,
        };
      })
      .filter(Boolean);
  }

  function draw(root) {
    const items = Array.from(root.querySelectorAll(":scope > .semantic-roadmap-item"));
    root.style.setProperty("--roadmap-count", String(Math.max(items.length, 1)));
    if (!items.length) return;

    const orientation = effectiveOrientation(root);
    root.dataset.roadmapEffectiveOrientation = orientation;
    const curve = curveValue(root);
    if (orientation === "horizontal") setHorizontalGeometry(root, items, curve);
    else setVerticalGeometry(root, items, curve);

    requestAnimationFrame(() => {
      const svg = ensureSvg(root);
      const width = Math.max(root.clientWidth, 1);
      const height = Math.max(root.clientHeight, 1);
      svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
      const path = catmullRomPath(markerPoints(root, items));
      svg.querySelectorAll("path").forEach((node) => node.setAttribute("d", path));
    });
  }

  function init(root) {
    if (root.dataset.roadmapReady === "true") return;
    root.dataset.roadmapReady = "true";
    let frame = null;
    const schedule = () => {
      if (frame !== null) cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => {
        frame = null;
        draw(root);
      });
    };

    schedule();
    if ("ResizeObserver" in window) new ResizeObserver(schedule).observe(root);
    window.addEventListener("resize", schedule, { passive: true });
  }

  function initialise() {
    document.querySelectorAll(".semantic-roadmap").forEach(init);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialise, { once: true });
  } else {
    initialise();
  }
})();
