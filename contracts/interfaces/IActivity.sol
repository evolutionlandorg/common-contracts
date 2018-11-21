pragma solidity ^0.4.24;

contract IActivity {
    function activityStopped(uint256 _tokenId) public;

    function isActivity() public returns (bool);
}