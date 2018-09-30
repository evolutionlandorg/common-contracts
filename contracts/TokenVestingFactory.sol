pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/TokenVesting.sol";

contract TokenVestingFactory {
    // index of created contracts
    address[] public contracts;

    // useful to know the row count in contracts index
    function getContractCount() public constant returns(uint contractCount)
    {
        return contracts.length;
    }

    // deploy a new contract
    function newTokenVesting(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable) public returns(address newContract)
    {
        TokenVesting tv = new TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable);
        contracts.push(tv);
        return tv;
    }
}