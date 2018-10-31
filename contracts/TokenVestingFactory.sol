pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/TokenVesting.sol";

contract TokenVestingFactory is Ownable {
    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);
    
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

    function revokeVesting(uint256 _contractIndex, ERC20Basic _token) public onlyOwner {
        TokenVesting(contracts[_contractIndex]).revoke(_token);
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }
}