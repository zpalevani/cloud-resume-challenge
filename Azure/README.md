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

# Jan 2, 2026

I continued the day to make the actual domain work. 

**Result:** ✅ Frontend is live at [https://cloudwithzarapalevani.space](https://cloudwithzarapalevani.space) using Azure Front Door + Azure DNS

This journal documents *exactly* what was done, where I went wrong initially, how I debugged it, and the precise steps that resolved the issue. This is written as a real technical log, not a cleaned-up success story.

---

## 1. Initial Goal

Launch the **Azure Cloud Resume Challenge frontend** using:

* Azure Front Door (Standard/Premium)
* Azure Storage static website (origin)
* Custom domain: `cloudwithzarapalevani.space`
* HTTPS with Azure-managed certificate
* Infrastructure-first mindset (IaC where possible, portal only when required)

---

## 2. Initial Architecture (Intended)

```
User
  → cloudwithzarapalevani.space
      → Azure Front Door
          → Azure Storage Static Website
```

Key assumptions at the start:

* Cloudflare would be used for DNS (based on prior AWS/GCP projects)
* Azure Front Door would issue and bind the TLS certificate automatically

---

## 3. The Core Problem (What Was Actually Broken)

### Symptom

* `*.azurefd.net` endpoint worked
* Custom domain did **not** work
* Browser errors included:

  * `NET::ERR_CERT_COMMON_NAME_INVALID`
  * `DNS_PROBE_FINISHED_NXDOMAIN`

### Misleading Signals

* Azure Front Door UI showed:

  * Domain: *Approved*
  * Certificate: *Deployed*
* Cloudflare DNS records looked correct

Despite this, HTTPS **never stabilized**.

---

## 4. The Real Root Cause (Critical Insight)

### The mistake

I was managing DNS records in **Cloudflare**, but the **domain registrar (Namecheap) was NOT delegating authority to Cloudflare**.

This created **split-brain DNS**:

* Some resolvers hit Namecheap DNS
* Some hit Cloudflare DNS
* Azure Front Door could not reliably validate or bind the certificate

No amount of Front Door tweaking, cache purging, or route toggling could fix this.

### The key realization

> **DNS record correctness does not matter if the DNS provider is not authoritative.**

The fix was **not** changing records — it was changing **who controls the zone**.

---

## 5. The Actual Fix (What Solved Everything)

### Step 1 — Delegate the domain to Azure DNS

In **Namecheap → Domain → Nameservers**:

Set nameservers to:

```
NS1-01.AZURE-DNS.COM
NS2-01.AZURE-DNS.NET
NS3-01.AZURE-DNS.ORG
NS4-01.AZURE-DNS.INFO
```

This made **Azure DNS the single source of truth**.

Verification:

```bash
whois cloudwithzarapalevani.space
```

Expected output:

```
Name Server: NS1-01.AZURE-DNS.COM
Name Server: NS2-01.AZURE-DNS.NET
Name Server: NS3-01.AZURE-DNS.ORG
Name Server: NS4-01.AZURE-DNS.INFO
```

---

## 6. Correct Azure DNS Records

Once Azure DNS was authoritative, **all DNS had to live there**.

### Apex domain record

* **Type:** A
* **Name:** (empty / `@`)
* **IP:**

  ```
  13.107.246.40
  ```

  (Azure Front Door anycast IP)

### WWW record

* **Type:** CNAME
* **Name:** `www`
* **Target:**

  ```
  crc-afd-endpoint-bfagazhrbbfxf5dr.z02.azurefd.net
  ```

No other records were required.

---

## 7. DNS Verification (Source of Truth)

```bash
dig +short cloudwithzarapalevani.space
```

Expected:

```
13.107.246.40
```

```bash
dig +short www.cloudwithzarapalevani.space
```

Expected:

```
crc-afd-endpoint-...azurefd.net
```

This confirmed DNS was **fully correct**.

---

## 8. TLS Certificate Debugging (Important Lesson)

Azure Front Door issues certificates **asynchronously**.

Even when:

* DNS is correct
* Domain is approved
* Route is attached

The cert may still serve the **default Azure cert** temporarily.

### The only reliable test

```bash
echo | openssl s_client \
-servername cloudwithzarapalevani.space \
-connect cloudwithzarapalevani.space:443 2>/dev/null \
| openssl x509 -noout -subject
```

### Final successful output

```
subject=CN = cloudwithzarapalevani.space
```

This was the definitive confirmation that:

* TLS certificate was live
* Front Door binding was complete

Browser errors after this point were **local cache only**.

---

## 9. What I Learned (Key Takeaways)

1. **DNS authority matters more than DNS records**
2. Cloud platforms will happily show "green" states even when DNS is split
3. Azure Front Door certificate lifecycle is opaque and slow
4. `openssl` is more reliable than the Azure Portal UI
5. Frontend issues must be fully resolved before touching backend work

---

## 10. Final State

* ✅ Domain delegated to Azure DNS
* ✅ Azure DNS records correct
* ✅ Azure Front Door routing correct
* ✅ Azure-managed TLS certificate live
* ✅ Frontend accessible at custom domain

This closed the frontend infrastructure phase of the Azure Cloud Resume Challenge.

The success was short lived and the website went down again. 

## The DNS & SSL Post-Mortem (The Pivot)
The most challenging aspect of this phase was achieving a "Green Lock" (HTTPS) across both the Apex domain and the `www` subdomain.

### The Problem: Split DNS Authority
Initially, I managed records in Cloudflare while the domain was registered at Namecheap. This created a "split-brain" scenario where Azure Front Door could not reliably validate ownership. The site suffered from `DNS_PROBE_FINISHED_NXDOMAIN` and `NET::ERR_CERT_COMMON_NAME_INVALID` errors.

### The Critical Realization
Managing DNS records is irrelevant if the **DNS Authority** is not correctly delegated at the registrar level. Waiting for propagation is useless if the source of truth is fragmented.

### The Solution: Consolidating to Azure DNS
The fix required moving the entire DNS control plane to Azure.
1.  **Delegation:** Updated the Nameservers at Namecheap to point exclusively to Azure DNS:
    *   `ns1-01.azure-dns.com`
    *   `ns2-01.azure-dns.net` (etc.)
2.  **Validation:** Used the `_dnsauth` TXT record to prove ownership to the Front Door certificate authority.
3.  **Association:** Associated both the Apex (`@`) and `www` domains to the Front Door route.

**Technical Verification Commands:**
```bash
# Check nameserver delegation
whois cloudwithzarapalevani.space | grep "Name Server"

# Verify DNS resolution for the endpoint
dig +short cloudwithzarapalevani.space

# Interrogate the SSL handshake to ensure the correct certificate is served
echo | openssl s_client -servername www.cloudwithzarapalevani.space -connect www.cloudwithzarapalevani.space:443 2>/dev/null | openssl x509 -noout -subject
```

---

## Final Configuration State
*   **Apex (`cloudwithzarapalevani.space`):** Resolved via an A-record (Alias) to the Front Door Anycast IP.
*   **Subdomain (`www`):** Resolved via CNAME to the Front Door endpoint.
*   **Redirect Logic:** Implemented a Front Door Rule Set (`redirectwwwtoapex`) to perform a 301 redirect from `www` to the Apex, ensuring a single, secure entry point.

## Lessons Learned
*   **Handshake Before Redirect:** In an HTTPS request, the SSL handshake happens *before* the redirect. Without a valid certificate for `www`, the redirect rule will never execute because the browser kills the connection first.
*   **Platform Opaque States:** Azure Front Door may report "Succeeded" or "Deployed" in the portal while the global edge nodes are still updating. Technical validation via `curl` and `openssl` is the only true way to verify status.

---

**Status:** ✅ Frontend is live, secure, and fully automated. Moving to Phase 2 (Backend).

<img src="zara azure.png" alt="cloudwithzara via Azure" width="900">

# Backend Work

# Azure Backend – Visitor Counter (Technical Journal)

## Overview

This backend completes the **Azure Cloud Resume Challenge** by providing a serverless, low-cost, production-style visitor counter. The goal was not just to "make it work", but to understand the **real Azure trade-offs**, constraints, and operational considerations that show up outside of tutorials.

The final solution uses:

* Azure Functions (Python, Consumption Plan)
* Azure Storage Account (Table API)
* Bicep for Infrastructure as Code (IaC)
* Azure CLI + Functions Core Tools for deployment

This document captures **what I built, why I built it this way, and the exact commands used**, in my own words.

---

## High-Level Architecture

**Flow**:

1. Frontend JavaScript calls a public HTTP endpoint
2. Azure Function receives the request
3. Function reads / increments a counter in Azure Table Storage
4. Function returns the updated count as JSON

**Key design choice**: keep the backend **stateless**, with state stored in Table Storage.

---

## Backend Technology Choices

### Azure Functions (Python)

* **Plan**: Consumption (Y1)
* **OS**: Linux
* **Runtime**: Python (Functions v4)

Why:

* Zero idle cost
* Scales automatically
* Native fit for small, event-driven logic
* Industry-standard for lightweight APIs

### Azure Storage – Table API

* Used as a simple key/value store
* Single entity pattern:

  * PartitionKey: `visitors`
  * RowKey: `resume`

Why:

* Extremely cheap
* No schema overhead
* Perfect for a single counter
* No need for Cosmos DB complexity

### Bicep (Infrastructure as Code)

Bicep was used to declaratively create:

* Storage Account
* Table Service + Table
* Consumption App Service Plan
* Linux Function App with managed identity

Why:

* Repeatable
* Auditable
* Matches real enterprise deployment patterns

---

## Folder Structure (Backend Only)

```
Azure/
└── backend/
    ├── bicep/
    │   └── main.bicep
    ├── function/
    │   ├── counter/
    │   │   ├── __init__.py
    │   │   └── function.json
    │   ├── requirements.txt
    │   └── host.json
    └── README.md
```

Clear separation between **infrastructure** and **application code**.

---

## Infrastructure Deployment (Bicep)

### Deployment Strategy

* Resource Group already existed
* Backend deployed independently from frontend
* Region changed to avoid subscription quota limitations

Final backend region:

```
canadacentral
```

### Command Used

```bash
az deployment group create \
  --resource-group crc-azure-rg \
  --template-file main.bicep \
  --parameters \
    location=canadacentral \
    storageAccountName=crczaravisitor<unique> \
    functionAppName=crc-visitor-fn \
    planName=crc-visitor-plan
```

### Important Azure Reality

* Linux Consumption Functions are **not deterministic** when deployed via ARM/Bicep
* Setting `linuxFxVersion` caused repeated deployment failures
* Final solution intentionally **lets Azure infer runtime**, which is a real-world workaround used by experienced teams

---

## Function Application Code

### Dependencies

`requirements.txt`

```txt
azure-data-tables
azure-identity
```

### Function Behavior

* HTTP-triggered
* Anonymous access
* Handles CORS
* Idempotent table creation
* Atomic counter increment using upsert

Key design decisions:

* Single-row counter pattern
* Merge updates to avoid overwrites
* Explicit error handling

---

## Application Settings

Set via Azure CLI (not hardcoded):

```bash
az functionapp config appsettings set \
  --name crc-visitor-fn \
  --resource-group crc-azure-rg \
  --settings \
    AZURE_STORAGE_CONNECTION_STRING="<connection-string>" \
    TABLE_NAME="VisitorCounter"
```

Why:

* No secrets in Git
* Environment-specific configuration
* Matches enterprise best practices

---

## Function Deployment

Deployed using Azure Functions Core Tools:

```bash
func azure functionapp publish crc-visitor-fn
```

Why:

* Avoids ARM runtime bugs
* Deterministic
* Fast iteration

---

## Security Considerations

### What Was Done

* No secrets committed to Git
* Storage access controlled via connection string
* HTTPS-only Function App
* Minimal surface area (single endpoint)

### Intentional Trade-offs

* Function is publicly accessible (by design)
* No auth layer added to keep challenge scope focused

### What I Would Do in Production

* Use Managed Identity instead of connection strings
* Restrict Function access via Front Door or API Management
* Enable Application Insights
* Add rate limiting

---

## Lessons Learned

* Azure behaves differently across subscriptions and regions
* IaC is powerful, but knowing **when not to over-specify** matters
* Debugging quota and platform constraints is real cloud work
* Confidence comes from seeing the full stack, not memorizing syntax

---

## Final Outcome

This backend is:

* Live
* Serverless
* Low-cost
* Explainable end-to-end

More importantly, I now understand **how and why it works**, and I can confidently discuss the architecture, trade-offs, and failure modes.

That was the real win for me!

![Cloud Resume Challenge on Azure with visitor counter](Azure/zara-azure-counter.png)


 For the website, given this is a Microsoft Azure project I used **Fluent Design System (Microsoft)** 
 Used for Windows and Microsoft 365. It focuses on "Light, Depth, Motion, Material, and Scale," moving away from the old flat "Metro" style.
