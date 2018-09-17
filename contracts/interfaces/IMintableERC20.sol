pragma solidity ^0.4.23;

interface IMintableERC20 {

    function mint(address _to, uint256 _value) public;
}