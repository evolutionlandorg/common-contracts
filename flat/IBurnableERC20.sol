// Root file: contracts/interfaces/IBurnableERC20.sol

pragma solidity ^0.4.23;

contract IBurnableERC20 {
    function burn(address _from, uint _value) public;
}