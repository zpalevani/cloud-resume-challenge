(function () {
  console.log("Cloud Resume frontend loaded:", new Date().toISOString());

  // Build script replaces this placeholder from frontend/flavors/aws.json
  const COUNTER_API_BASE = "__COUNTER_API_BASE__";

  const counterEl = document.getElementById("view-count");

  if (!counterEl) {
    console.warn("view-count element not found in DOM");
    return;
  }

  if (!COUNTER_API_BASE || !COUNTER_API_BASE.startsWith("http")) {
    counterEl.textContent = "0";
    return;
  }

  const base = COUNTER_API_BASE.replace(/\/+$/, "");
  const endpoint = `${base}/counter`;

  async function increment() {
    const res = await fetch(endpoint, { method: "POST" });
    if (!res.ok) throw new Error(`POST failed: ${res.status}`);
    const data = await res.json();
    return data.count;
  }

  // Increment once per page load — no placeholder flash
  (async () => {
    try {
      const updated = await increment();
      counterEl.textContent = updated;
    } catch (err) {
      console.error("Visitor counter error:", err);
      // keep previous value, fail silently
    }
  })();
})();
