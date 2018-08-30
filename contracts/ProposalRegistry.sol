pragma solidity ^0.4.24;

import "./interfaces/IAuthority.sol";
import "./Proposal.sol";
import "./KtonVoter.sol";

contract ProposalRegistry is IAuthority {

    // refer https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol
    // TODO: We can create a similar VoterWallet.sol
    mapping (uint => Proposal) public proposals;
    mapping (uint => mapping (address => bool)) public confirmations;

    mapping (address => bool) public proposalsApproved;

    KtonVoter public voter;

    uint public required;

    uint public transactionCount;

    function executeProposal(uint proposalId) public {
        // TODO
        proposals[proposalId].doSomething();
    }

    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool)
    {
        if (proposalsApproved[src])
        {
            return Proposal(src).canCall(src, dst, sig);
        }
    }
}