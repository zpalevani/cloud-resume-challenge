document.addEventListener("DOMContentLoaded", async () => {
  const el = document.getElementById("count");
  if (!el) return;

  const API_URL = "https://crc-visitor-fn.azurewebsites.net/api/count";

  try {
    const res = await fetch(API_URL, { method: "GET" });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);

    const data = await res.json();
    el.textContent = data.count;
  } catch (err) {
    console.error("Visitor counter error:", err);
    // Keep a readable fallback instead of breaking the page
    el.textContent = "—";
  }
});
