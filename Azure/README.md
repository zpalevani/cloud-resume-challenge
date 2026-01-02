# Jan 1, 2026

# Azure Cloud Resume Challenge — Frontend Journal

This journal starts **from the very beginning**, documenting the **initial Azure project structure setup** and then walking through the frontend build end‑to‑end. The intent is to show deliberate system design, clean separation of concerns, and an Infrastructure‑as‑Code mindset from day one.

---

## Initial Project Structure

The Azure work lives inside the existing Cloud Resume Challenge repository under a dedicated `Azure/` directory. The structure was created first, before any resources were deployed, to avoid drift and ad‑hoc files later.

```
Azure/
├── ansible/        # Orchestration layer (runs deployments, uploads, purges)
├── backend/        # Azure Functions + Cosmos DB code (next phase)
├── bicep/          # Declarative Azure infrastructure
│   └── frontend.bicep
├── journal/        # Technical journal entries (this file lives here)
├── scripts/        # Helper scripts (if/when needed)
├── site/           # Static frontend assets
│   ├── index.html
│   ├── styles.css
│   ├── script.js
│   ├── blog.html
│   ├── 404.html
│   └── zara palevani-azure.png
├── .gitignore
└── README.md
```

Design principles behind this structure:

* **Clear separation of concerns** (infra vs orchestration vs app code)
* **Frontend and backend decoupled** from day one
* **Journal treated as a first‑class artifact**, not an afterthought
* Easy future extension without restructuring

---

## Git Hygiene & Security Baseline

Before deploying anything, an Azure‑specific `.gitignore` was added to ensure:

* No credentials or keys are ever committed
* No Azure CLI state leaks into source control
* No Ansible retry files or build artifacts tracked

This step prevents accidental exposure early and avoids cleanup later.

---

## Frontend Build — Architecture Overview

This journal documents **everything completed so far on the Azure frontend** of my Cloud Resume Challenge. The focus is on *final, working solutions* rather than experimentation. All infrastructure was approached **Infrastructure-as-Code first**, using automation wherever possible and falling back to the Azure Portal only when the platform realistically required it.

---

## Architecture Overview (Frontend)

```
Browser
  │
  ▼
Cloudflare (DNS)
  │
  ▼
Azure Front Door (HTTPS, caching, routing)
  │
  ▼
Azure Storage Account (Static Website)
  │
  ▼
HTML / CSS / JS (Resume UI + Counter Placeholder)
```

Key design goals:

* Static, globally accessible resume site
* HTTPS enabled end-to-end
* Clean DNS separation from hosting
* Fully repeatable deployments
* Low cost / near-zero idle cost

---

## Stack Used

### Frontend Hosting

* **Azure Storage Account (StorageV2)**
* Static website enabled via Blob service (`$web` container)

### Edge & Networking

* **Azure Front Door (Standard)**

  * HTTPS enforcement
  * Caching + compression
  * Global routing
* **Cloudflare**

  * DNS hosting for custom domain
  * Used as authoritative DNS (not hosting)

### Automation & IaC

* **Bicep** — declarative Azure infrastructure
* **Ansible** — orchestration and repeatable deployment
* **Azure CLI** — execution layer

### Frontend Code

* HTML / CSS / JavaScript
* No frameworks
* Explicit, readable structure

---

## Domain & DNS Decisions

* Domain: `cloudwithzarapalevani.space`
* Registrar: Namecheap
* DNS Provider: Cloudflare
* Hosting: Azure

Rationale:

* DNS decoupled from cloud provider
* Allows future migration without touching registrar
* Industry-realistic setup

Steps:

1. Added domain to Cloudflare
2. Updated Namecheap nameservers to Cloudflare
3. Managed DNS records in Cloudflare only

---

## Azure Region

* **eastus**

Chosen for:

* Broad service availability
* Lower latency to North America
* Stable defaults for Azure Front Door

---

## Infrastructure as Code — Bicep

A single Bicep template provisions:

* Resource Group
* Storage Account
* Static Website configuration
* Azure Front Door profile
* Front Door endpoint
* Origin group + origin pointing to Storage static website
* HTTPS redirect
* Compression settings

Key output values:

* Storage static website endpoint
* Front Door default hostname (`*.azurefd.net`)

The Bicep file is executed *only* via automation (never manually in portal).

---

## Orchestration — Ansible

Ansible is used to:

1. Ensure the resource group exists
2. Deploy the Bicep template
3. Upload frontend files to the `$web` container
4. Output key deployment URLs

### Key Ansible Command

```bash
ansible-playbook -i localhost, playbooks/frontend-deploy.yml
```

### Upload Mechanism

Uses Azure CLI under the hood:

```bash
az storage blob upload-batch \
  --account-name <storage_account> \
  --destination '$web' \
  --source Azure/site \
  --overwrite
```

This ensures the site is always deployed from source control.

---

## Azure Front Door Configuration

Azure Front Door is used instead of Azure CDN to align with modern Azure patterns.

Configured features:

* Global endpoint
* HTTPS enforced
* Compression enabled for:

  * HTML
  * CSS
  * JavaScript
  * JSON
  * SVG
* Routing rules applied at the edge

Front Door acts as the **only public-facing entry point** to the site.

---

## Custom Domain & HTTPS

* Custom domain added to Azure Front Door
* Domain ownership validated via DNS record in Cloudflare
* Azure-managed TLS certificate enabled

Why Portal Was Used Here:

* Domain validation and certificate provisioning is significantly clearer and faster via the Azure UI
* This is a known, acceptable exception even in IaC-first workflows

---

## Frontend Code Structure

```
Azure/site
├── index.html
├── styles.css
├── script.js
├── blog.html
├── 404.html
└── zara palevani-azure.png
```

### UI Highlights

* Clean, professional layout
* Photo integrated into hero section
* Text-based nav replaced with modern SVG icons
* Fully responsive

---

## Visitor Counter (Placeholder)

A counter placeholder is intentionally included **before backend integration**.

### HTML

```html
<div class="counter">
  Visitors: <span id="count">coming soon</span>
</div>
```

### JavaScript

```js
document.addEventListener("DOMContentLoaded", () => {
  const el = document.getElementById("count");
  if (!el) return;
  el.textContent = "coming soon";
});
```

This keeps the frontend deployable and stable while the backend is built independently.

---

## Security & Cost Considerations

* No secrets stored in frontend
* No backend endpoints exposed yet
* Storage account uses static website only
* Front Door provides HTTPS termination
* Idle cost is effectively zero

---

## Git Hygiene

An Azure-specific `.gitignore` ensures:

* No credentials committed
* No build artifacts tracked
* No local Azure or Ansible state leaked

---

## Current Status

✅ Frontend infrastructure fully deployed
✅ Custom domain active
✅ HTTPS enabled
✅ Site content live
✅ Counter placeholder visible

---

## Next Phase

The next phase will introduce:

* Azure Function (HTTP-triggered)
* Cosmos DB (Table API)
* API integration with frontend counter
* CI/CD pipelines

This frontend foundation is now stable, automated, and ready for backend integration.

