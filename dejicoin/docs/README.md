# Dejicoin Documentation

Welcome to the official **Dejicoin (DEJI)** documentation directory.  
Dejicoin represents **true decentralization** — a token on **Binance Smart Chain (BSC)** with **renounced ownership**, **locked liquidity**, and **on-chain community governance**.

---

## 📂 Included Documents

| File | Description |
|------|--------------|
| **whitepaper.pdf** | Complete technical and economic overview of Dejicoin. |
| **roadmap.md** | Transparent development and decentralization milestones. |
| **deployment_remix.md** | Step-by-step guide to deploy via Remix while preserving full decentralization. |
| **deployment_verification_form.md** | Post-deployment verification checklist confirming renouncement, governance setup, and liquidity burn. |
| **manual_test_checklist.md** | Manual functional test list for validating contract behavior on Remix. |
| **README.md** | This index file — overview of documentation contents. |

---

## 🧭 Philosophy

> “Locked Liquidity. Burned Control. True Freedom.”

Dejicoin exists to prove that a token can thrive **without a central authority**.  
All power resides in the community through **TimelockController** and **Governor** smart contracts, ensuring transparent and immutable governance.

---

## 🛠 Technical Summary

- **Blockchain:** Binance Smart Chain (BEP-20 Standard)  
- **Solidity Version:** `^0.8.30`  
- **Supply:** Fixed – No minting or pausing after deployment  
- **Governance:** OpenZeppelin TimelockController + Governor  
- **Admin Ownership:** Fully renounced (no private control)  
- **Liquidity:** Permanently burned  
- **Deployment:** 100% manual via Remix (no deploy scripts, no keys)  
- **Audit Readiness:** Code structured for community verification and transparency  

---

## 🧪 Usage Overview

This documentation suite serves three audiences:

| Role | File to Use | Purpose |
|------|--------------|---------|
| **Deployers** | `deployment_remix.md` | Step-by-step instructions for safe decentralized deployment. |
| **Auditors / Verifiers** | `deployment_verification_form.md` | Validate that contracts meet all decentralization and immutability criteria. |
| **Testers / Contributors** | `manual_test_checklist.md` | Perform on-chain Remix tests to confirm functionality. |

---

## 🧠 Governance Architecture

| Component | Purpose |
|------------|----------|
| **Dejicoin Token** | BEP-20 token with renounced ownership. |
| **DejiGovernor** | Handles voting and proposal logic. |
| **TimelockController** | Enforces governance delays and proposal execution rules. |

Each proposal flows through:  
**Governor → Timelock → Execution**, guaranteeing **no instant or private actions**.

---

## ⚖️ Compliance and Licensing

All source code is licensed under the **MIT License (2025, Dejicoin)**.  
Contributions must follow the decentralization and transparency principles defined in [`CONTRIBUTING.md`](../CONTRIBUTING.md) and [`SECURITY.md`](../SECURITY.md).

---

## 📬 Contact

- 🌐 **Website:** [www.dejicoin.com](https://www.dejicoin.com)  
- 📧 **Email:** [dejicoin@gmail.com](mailto:dejicoin@gmail.com)  

---

## ✅ Community Statement

Dejicoin is not controlled by any developer, company, or admin.  
Its security, growth, and governance belong entirely to the **community**.

> “Every block builds trust — every holder holds power.”

---

