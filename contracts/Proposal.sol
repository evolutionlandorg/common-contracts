pragma solidity ^0.4.24;

import "./interfaces/IAuthority.sol";

contract Proposal is IAuthority {

    function doSomething() public {
        // do changes to destiantion
    }

    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool)
    {
        if (src == address(this))
        {
            return true;
        }
    }
}