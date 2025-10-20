// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Modern OpenZeppelin imports (v5.x structure)
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol"; 
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol"; 
// (The problematic ProposalState import is gone)


/// ------------------------------
/// 1) DEJI Token (Ownerless + No Mint/Burn)
/// ------------------------------
contract Dejicoin is ERC20, ERC20Permit, ERC20Votes {

    uint256 private constant TOTAL_SUPPLY = 15_000_000;
    
    constructor(address walletToMintTo)
        ERC20("Dejicoin", "DEJI")
        ERC20Permit("Dejicoin")
        ERC20Votes()
    {
        uint256 supply = TOTAL_SUPPLY * 10 ** decimals();
        _mint(walletToMintTo, supply);
    }

    // Universal hook for all supply changes (mint, burn, transfer)
    function _update(address from, address to, uint256 value)
        internal
        virtual
        override(ERC20, ERC20Votes)
    {
        // Enforce No Minting
        if (from == address(0) && totalSupply() > 0) {
            revert("Minting is disabled after initial supply");
        }

        // Enforce No Burning
        if (to == address(0)) {
            revert("Burning is permanently disabled");
        }

        super._update(from, to, value);
    }

    // Resolves conflict between ERC20Permit and Nonces
    function nonces(address owner)
        public
        view
        virtual
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}

/// ------------------------------
/// 2) DejiGovernor
/// ------------------------------
contract DejiGovernor is
    Governor,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    // Immutable storage for configuration parameters
    uint256 public immutable _votingDelay;
    uint256 public immutable _votingPeriod;
    uint256 public immutable _proposalThreshold;

    constructor(
        IVotes token_,
        TimelockController timelock_,
        uint256 votingDelay_,
        uint256 votingPeriod_,
        uint256 proposalThreshold_,
        uint256 quorumFraction_
    )
        Governor("DejiGovernor")
        GovernorVotes(token_)
        GovernorVotesQuorumFraction(quorumFraction_)
        GovernorTimelockControl(timelock_)
    {
        _votingDelay = votingDelay_;
        _votingPeriod = votingPeriod_;
        _proposalThreshold = proposalThreshold_;
    }

    // Governor Settings Function Overrides (Expose immutable values)
    function votingDelay() public view virtual override returns (uint256) {
        return _votingDelay;
    }

    function votingPeriod() public view virtual override returns (uint256) {
        return _votingPeriod;
    }

    function proposalThreshold() public view virtual override returns (uint256) {
        return _proposalThreshold;
    }
    
    // Multiple Inheritance Conflict Resolution: Queue
    // FIX: Reverted the body to use 'super' to fix the differing return types error.
    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }
    
    // Multiple Inheritance Conflict Resolution: Execute
    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    // Multiple Inheritance Conflict Resolution: proposalNeedsQueuing
    function proposalNeedsQueuing(uint256 proposalId) 
        public 
        view 
        virtual 
        override(Governor, GovernorTimelockControl) 
        returns (bool) 
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    // Required overrides for core Governor functions
    function state(uint256 proposalId)
        public
        view
        virtual
        override(Governor, GovernorTimelockControl) 
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    // Multiple Inheritance Conflict Resolution: cancel
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )
        internal
        virtual
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    // Multiple Inheritance Conflict Resolution: executor
    // FIX: Reversed order to (GovernorTimelockControl, Governor) to satisfy strict compilers.
    function _executor()
        internal
        view
        virtual
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    // Multiple Inheritance Conflict Resolution: supportsInterface
    // FIX: Reversed order to (GovernorTimelockControl, Governor) to satisfy strict compilers.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(Governor)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

/// ------------------------------
/// 3) DejiDeployer (Automated + Transparent + Fully Decentralizing)
/// ------------------------------
contract DejiDeployer {
    Dejicoin public token;
    TimelockController public timelock;
    DejiGovernor public governor;

    event Deployed(address token, address timelock, address governor);

    constructor(address walletToMintTo) {
        // Governance Parameters
        uint256 minDelay = 86400; // 1 day (Timelock delay)
        uint256 votingDelay_ = 5760; // Blocks (Voting starts after this many blocks)
        uint256 votingPeriod_ = 40320; // Blocks (Voting lasts for this many blocks)
        uint256 proposalThreshold_ = 150000000000000000000000; // 150,000 DEJI (150k * 10^18)
        uint256 quorumFraction_ = 4; // 4% of total supply

        // Timelock setup
        address[] memory proposers = new address[](0);
        address[] memory executors = new address[](1);
        executors[0] = address(0); // Anyone can execute (zero address)

        // 1. Deploy Token
        token = new Dejicoin(walletToMintTo);

        // 2. Deploy Timelock (Admin is initially DejiDeployer)
        timelock = new TimelockController(minDelay, proposers, executors, address(this));
        
        // 3. Deploy Governor
        governor = new DejiGovernor(
            IVotes(address(token)),
            timelock,
            votingDelay_,
            votingPeriod_,
            proposalThreshold_,
            quorumFraction_
        );

        // 4. Finalize Decentralization
        timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
        timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), address(this));

        emit Deployed(address(token), address(timelock), address(governor));
    }
}