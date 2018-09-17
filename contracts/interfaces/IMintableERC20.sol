pragma solidity ^0.4.23;

interface MintableERC20 {

    function mint(address _to, uint256 _value) public;
}