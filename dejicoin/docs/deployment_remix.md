# Remix Deployment Guide (Manual)

This guide ensures you deploy **Dejicoin** in a **fully decentralized** and **audit-ready** manner — no admin keys, no upgradeability, and no hidden control.

---

## ⚙️ 1. Compile

1. Open [Remix IDE](https://remix.ethereum.org/).  
2. Load your single Solidity file:  
   `contracts/Dejicoin.sol` (which contains token, governor, and timelock logic).
3. Select **Solidity Compiler** → Version **0.8.30** (or your exact pragma version).  
4. Enable “Auto Compile” and “Optimization = 200 runs.”  
5. Click **Compile Dejicoin.sol**.  
   - ✅ Ensure **no warnings** and **no SPDX/license errors**.

---

## 🚀 2. Deploy Token

1. Go to **Deploy & Run Transactions** tab.  
2. Select **Injected Web3** (MetaMask or other wallet).  
3. Choose the correct network:
   - Testnet (BSC Testnet) for trial  
   - Mainnet (BSC Mainnet) for production
4. Select **Dejicoin** contract in the dropdown.
5. Enter constructor arguments (if applicable):

initialSupply = 15000000 ether


*(Example: 15 million tokens with 18 decimals)*  
6. Click **Deploy** → Confirm in wallet.
7. Wait for confirmation → copy the **Dejicoin contract address**.

📋 **Record:**  
- Deployer address  
- Deployed contract address  
- Transaction hash  

---

## 🏛️ 3. Deploy Governance Components

If your `Dejicoin.sol` contains **TimelockController** and **DejiGovernor** as separate contracts:

### a. Deploy TimelockController
1. Select **TimelockController** from dropdown.
2. Constructor parameters:


minDelay = 3600 // 1 hour, or your chosen governance delay
proposers = [] // Leave blank
executors = [] // Leave blank
admin = 0x0000000000000000000000000000000000000000

3. Click **Deploy** → Confirm.
4. Copy the **Timelock address**.

### b. Deploy DejiGovernor
1. Select **DejiGovernor**.
2. Constructor parameters:

token = <Dejicoin address>
timelock = <Timelock address>

3. Click **Deploy** → Confirm.
4. Copy **Governor address**.

---

## 🔗 4. Configure Roles (Timelock setup)

Now connect governance and timelock properly:

1. In **TimelockController**:
- Grant proposer role to Governor:  
  `grantRole(PROPOSER_ROLE, <Governor address>)`
- Grant executor role to **zero address** (for open execution):  
  `grantRole(EXECUTOR_ROLE, 0x0000000000000000000000000000000000000000)`
2. Verify using `hasRole(PROPOSER_ROLE, Governor)` → should return `true`.
3. Verify using `hasRole(EXECUTOR_ROLE, 0x000...0000)` → should return `true`.
4. **Revoke** any admin roles from deployer:  
`revokeRole(DEFAULT_ADMIN_ROLE, <your wallet address>)`
5. Confirm:
- `getRoleAdmin(PROPOSER_ROLE)` → Timelock itself.
- No external admin remains.

✅ **At this stage:** Timelock controls all privileged actions. You cannot modify directly.

---

## 🔒 5. Transfer Token Control

If your token inherits `Ownable`:

1. In **Dejicoin** contract:
- Option 1: Transfer ownership to Timelock:  
  `transferOwnership(<Timelock address>)`
- Option 2 (if governance is already initialized):  
  `renounceOwnership()`
2. Confirm:
- `owner()` → `0x0000000000000000000000000000000000000000`  
  *(if renounced)*  
  or → `<Timelock address>` *(if transferred)*

---

## 🧠 6. Governance Sanity Test

1. In **Governor**:
- Call `propose()` with a simple test proposal (e.g., `updateDelay()`).
- Wait for the voting period.
- Cast votes with multiple addresses.
- Queue → wait for delay → execute.
2. Confirm that execution happens only via Timelock.

---

## 🧾 7. Verify Contracts on BscScan

1. In Remix, go to **Solidity Compiler → Verify & Publish** or use the BscScan plugin.  
2. Upload **flattened source** (`Dejicoin.flat.sol`).  
3. Match compiler version and optimization settings.  
4. Submit → wait for green check ✅ “Contract verified.”

---

## 🔥 8. Burn Liquidity (Optional but recommended)

If liquidity is added manually:

1. Add DEJI–WBNB liquidity on PancakeSwap.
2. Receive LP tokens in your wallet.
3. Send all LP tokens to:

0x000000000000000000000000000000000000dEaD

4. Verify on BscScan under **LP Token Holders**:
- Dead address is top holder.
- No LP tokens in private wallets.

---

## 🔍 9. Final Verification Checklist

| Item | Expected Result |
|------|------------------|
| Ownership | `owner()` = zero or timelock |
| Timelock | Has proposer (Governor) & executor (zero addr) roles |
| Governance | Works end-to-end (propose → vote → execute) |
| LP Tokens | Sent to dead address |
| Mint/Burn | No mint function; burn disabled for control |
| Source | Verified on BscScan |
| Admin | No private admin roles left |

---

## 🗂️ 10. Recordkeeping

Before you announce full decentralization, **record and publish**:

- Token contract address  
- Governor address  
- Timelock address  
- LP burn transaction hash  
- Ownership renounce or transfer transaction hash  
- BscScan verification link

Save these in `docs/deployment_records.md` for transparency.

---

## ✅ Deployment Complete

🎉 Congratulations — Dejicoin is now **100% decentralized**.  
No one (including deployer) can modify, mint, or pause it.  
Every upgrade or proposal must go through on-chain governance.

---

**Contact:**  
For verification or community audit submissions —  
📧 dejicoin@gmail.com  
🌐 [www.dejicoin.com](https://www.dejicoin.com)
