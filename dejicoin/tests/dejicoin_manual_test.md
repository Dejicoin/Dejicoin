# Dejicoin Manual Test Checklist (Remix)

This checklist is intended for manual verification after each deployment (Testnet → Mainnet). Use Remix for calls/transactions and BscScan for on-chain verification.

> **Before you start:** open Remix, load `contracts/Dejicoin.sol` (single file containing token + governor + timelock), compile with `pragma solidity ^0.8.30`, and connect your wallet to the appropriate network.

---

## Quick reference
- Dead address to check LP burn / ownership renounce: `0x000000000000000000000000000000000000dEaD`
- Zero address: `0x0000000000000000000000000000000000000000`

---

## 1 — Token basics

| Test | Action (Remix) | Expected Result / How to verify |
|------|----------------|----------------------------------|
| Name & Symbol | Call `name()` and `symbol()` | `name()` → `Dejicoin`, `symbol()` → `DEJI` |
| Decimals | Call `decimals()` | Should return `18` (or expected decimals) |
| Total supply | Call `totalSupply()` | Matches constructor `initialSupply` (check units) |
| Owner check | Call `owner()` (if exists) | Returns `0x000...0000` or revert/undefined if non-ownable. If `owner()` exists and equals timelock address, that's acceptable. |
| Balance of deployer | Call `balanceOf(deployerAddress)` | Equals total supply if minted to deployer; otherwise matches expected allocation |
| Transfer | From deployer, call `transfer(addr, amount)` | Transaction succeeds; `balanceOf` updates accordingly |
| Transfer event | Watch `Transfer` event in Remix or BscScan | Emitted with `from`, `to`, `value` |
| Approve / Allowance | `approve(spender, amt)` then `allowance(owner, spender)` | `allowance` equals `amt` |
| transferFrom | From `spender`, call `transferFrom(owner, recipient, amt)` | Works when allowance sufficient; balances update |
| Edge decimals test | Transfer 1 unit (1 wei) / 1 token (1 * 10^decimals) | Numeric checks correct (no rounding) |

---

## 2 — Supply control & mutability

| Test | Action | Expected Result |
|------|--------|-----------------|
| Mint function existence | Search contract for `mint` | **No** public/external mint function present. If present, verify access is restricted to timelock/governor only. |
| Burn function existence | Search for `burn` | If present, confirm it's expected and allowed for token holders only (not privileged). If not expected — must be absent. |
| Pausable / Pause functions | Search for `pause`, `paused`, `unpause` | Should **not** exist unless explicitly part of design — if present, ensure only timelock/governor can call (and this should be documented). |
| Upgradeability | Search for proxy patterns | No proxies/upgradeable patterns should be present for pure decentralization. |

---

## 3 — Ownership & admin checks

| Test | Action | Expected Result |
|------|--------|-----------------|
| Ownership renounced | Call `owner()` and compare | Returns `0x000...0000` OR the timelock address (if ownership transferred to timelock). If timelock address, confirm timelock admin role is correct. |
| Renounce transaction proof | Check deploy transaction & ownership transfer tx on BscScan | Confirm the `transferOwnership` or `renounceOwnership` tx is present and successful. |
| No admin functions | Manually inspect source for `onlyOwner`, `onlyAdmin` modifiers | No remaining privileged modifier logic without timelock gating. |

---

## 4 — Liquidity (LP) burn / lock verification

| Test | Action | Expected Result |
|------|--------|-----------------|
| Add liquidity (example) | Create DEJI–WBNB pool on PancakeSwap (Testnet) | LP tokens minted to the wallet that supplied liquidity |
| Burn LP tokens | Send LP token balance to `0x000...dEaD` | Transaction succeeds; the LP token holder becomes dead address |
| Verify LP holders | On BscScan LP contract → Holders | Top holder = dead address, amount equals LP minted (or expected locked portion) |
| Verify pool immutability | Attempt to remove liquidity (from dead address) | Impossible — tokens at dead address cannot be withdrawn |

**Notes:** always keep Tx hashes and block numbers for audit traceability.

---

## 5 — Governance & Timelock checks

| Test | Action | Expected Result |
|------|--------|-----------------|
| Timelock deployed | Call `timelockAddress` functions (e.g., `getMinDelay()` or `minDelay()`) | Returns configured `minDelay` value |
| Timelock roles | Call `PROPOSER_ROLE()` and `EXECUTOR_ROLE()` on Timelock, then `hasRole(role, address)` | Governor must have PROPOSER role; executor may be `0x000...0000` if open execution desired or a multisig/timelock as per design |
| Governor propose -> queue -> execute lifecycle | Create proposal via `propose(...)` with correct calldata; follow voting period; after passing, `queue` (if needed) and `execute` after `minDelay` | Each stage should succeed; verify proposal state transitions (Pending → Active → Succeeded → Queued → Executed) |
| Voting records | After vote, call `getVotes(address, blockNumber)` or check Governor vote events | Votes counted correctly; quorum & thresholds respected |
| Proposal security | Ensure only governance (via timelock) can change critical params | Attempt to call sensitive functions directly — should revert when called by non-timelock |

---

## 6 — Event & logs checks

| Test | Action | Expected Result |
|------|--------|-----------------|
| Transfer events | Perform transfers | `Transfer` events emitted with correct parameters |
| Approval events | Approve and `transferFrom` | `Approval` events emitted |
| Governance events | Propose, vote, queue, execute | Governor emits `ProposalCreated`, `VoteCast`, `ProposalQueued`, `ProposalExecuted` etc. |

---

## 7 — Security & edge-case tests

| Test | Action | Expected Result |
|------|--------|-----------------|
| Reentrancy checks | Review functions handling external calls | No vulnerable external calls without reentrancy guard where needed |
| Overflow/underflow | Attempt large transfers around uint256 boundaries | No overflow due to Solidity 0.8 built-in checks |
| Zero-address transfers | Try `transfer(0x000...0000, amount)` | Behaves per ERC-20 (should revert or follow implementation) |
| Approve race | Attempt double-spend via race on allowances | Implementation should either follow OpenZeppelin pattern (use `increaseAllowance`/`decreaseAllowance`) or be safe per design |
| Gas sanity | Gas for typical operations (transfer, propose) | Gas cost reasonable (no unexpected huge gas) |

---

## 8 — On-chain verification & public transparency

| Test | Action | Expected Result |
|------|--------|-----------------|
| Source verification | Verify contract on BscScan with flattened source or correct compiler settings | Source verified (green check) |
| Contract metadata | Check contract README/docs link on BscScan | Whitepaper/docs linked in contract description / project details |
| Transaction provenance | Collect tx hashes: deploy, ownership transfer, LP burn | All present and match expected addresses and values |
| Bytecode match | Confirm published source matches on-chain bytecode | Verified compiler & optimization settings produce matching bytecode |

---

## 9 — Post-deployment operational checklist

- Archive and publish all important transaction hashes (deploy, ownership transfer, LP burn, timelock setup).  
- Publish flattened source (`Dejicoin.flat.sol`) to `contracts/` and verify on BscScan.  
- Announce governance addresses, timelock delay, and how to propose on your community channels.  
- Schedule independent audit and publish audit findings in `/audits`.  
- Keep a small public checklist in repo with links to the verification transactions.

---

## Example: How to run a propose → vote → execute test (Remix)

1. In Remix, connect to the same network and ensure `Dejicoin.sol` ABI is loaded for Governor and Timelock.
2. From a signer (who holds voting power), call `propose(targets, values, calldatas, description)`.
3. Record the proposal id from `ProposalCreated` event.
4. Wait for voting delay → call `castVote(proposalId, support)` from multiple signers to meet quorum.
5. After voting period ends and proposal succeeds, call `queue(proposalId)` (if required), then wait `minDelay`, then call `execute(proposalId)`.
6. Verify the intended state change occurred and events emitted.

---

## Notes & Troubleshooting

- If `owner()` returns deployer address after you expected renounce: check whether you transferred ownership to timelock instead of renouncing. Transferring to timelock is acceptable — in that case you must verify timelock roles.
- If governance functions are failing, verify the Governor contract address has been granted PROPOSER role in Timelock.
- For LP burn verification, ensure LP tokens you sent to `0x...dEaD` match the LP contract's holder list on BscScan.

---

## Final sign-off (for release)

Before listing or advertising Dejicoin as **fully decentralized**, confirm and record:

- [ ] Ownership renounced or transferred to timelock (with tx hash)  
- [ ] LP tokens burned or locked (with tx hash and BscScan holder proof)  
- [ ] Governor has proposer role and can create proposals (tx hash)  
- [ ] Timelock executor and minDelay configured as announced (tx hash)  
- [ ] Contract source verified on BscScan

---

**Keep this checklist with your repo under `tests/dejicoin_manual_test.md` and update it if your contract design changes.**
