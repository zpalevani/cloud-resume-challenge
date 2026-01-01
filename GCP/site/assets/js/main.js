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
  if (!visitorCountEl) return;

  // ✅ REAL Cloud Run endpoint
  const endpoint = "https://visitor-counter-jgrcbs6pfa-uc.a.run.app/count";

  fetch(endpoint, { method: "GET", cache: "no-store" })
    .then((r) => {
      if (!r.ok) throw new Error(`Visitor API HTTP ${r.status}`);
      return r.json();
    })
    .then((data) => {
      const count = data?.count;
      if (typeof count === "number") {
        visitorCountEl.textContent = count.toLocaleString();
      } else {
        visitorCountEl.textContent = "—";
      }
    })
    .catch((err) => {
      console.error("Visitor counter fetch failed:", err);
      visitorCountEl.textContent = "—";
    });
})();
