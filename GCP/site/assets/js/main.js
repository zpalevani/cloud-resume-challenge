// assets/js/main.js

(() => {
  // Footer year
  const yearEl = document.getElementById("year");
  if (yearEl) yearEl.textContent = new Date().getFullYear();

  // Drawer logic (only runs if elements exist — prevents homepage from going blank)
  const menuBtn = document.getElementById("menuBtn");
  const drawer = document.getElementById("drawer");
  const closeDrawerBtn = document.getElementById("closeDrawerBtn");
  const backdrop = document.getElementById("backdrop");

  if (menuBtn && drawer && closeDrawerBtn && backdrop) {
    const openDrawer = () => {
      drawer.setAttribute("aria-hidden", "false");
      backdrop.hidden = false;
    };

    const closeDrawer = () => {
      drawer.setAttribute("aria-hidden", "true");
      backdrop.hidden = true;
    };

    menuBtn.addEventListener("click", openDrawer);
    closeDrawerBtn.addEventListener("click", closeDrawer);
    backdrop.addEventListener("click", closeDrawer);
  }

  // Visitor counter (only runs if the element exists)
  const visitorCountEl = document.getElementById("visitorCount");
  if (visitorCountEl) {
    // If/when you wire your backend, point this to your real endpoint.
    // This won't break the page if the endpoint isn't live yet.
    const endpoint = "/api/visitors";

    fetch(endpoint, { method: "GET" })
      .then((r) => {
        if (!r.ok) throw new Error(`Visitor API HTTP ${r.status}`);
        return r.json();
      })
      .then((data) => {
        // Supports either { count: 123 } or { visits: 123 }
        const count = data?.count ?? data?.visits;
        if (typeof count === "number") visitorCountEl.textContent = String(count);
      })
      .catch(() => {
        // Keep your placeholder; don't crash UI
        visitorCountEl.textContent = "—";
      });
  }
})();
