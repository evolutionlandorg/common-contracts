pragma solidity ^0.4.24;

contract ICrossChainFees {
    function payTxFees(address _token, address _from, uint _value) public;
}