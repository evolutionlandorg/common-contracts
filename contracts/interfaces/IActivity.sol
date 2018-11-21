pragma solidity ^0.4.24;

contract IActivity {
    uint48 public constant MAX_UINT48_TIME = 281474976710655;
    
    function activityStopped(uint256 _tokenId) public;

    function isActivity() public returns (bool);
}