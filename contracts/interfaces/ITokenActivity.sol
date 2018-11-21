pragma solidity ^0.4.24;

contract ITokenActivity {
    uint48 public constant MAX_UINT48_TIME = 281474976710655;

    function isObjectInActivity(uint256 _tokenId) public view returns (bool);

    function getTokenOwner(uint256 _tokenId) public view returns (address);

    function getTokenUser(uint256 _tokenId) public view returns (address);

    function startTokenActivityFromContract(
        uint256 _tokenId, address _user, address _owner, uint256 _startTime, uint256 _endTime, uint256 _price) public;

    function stopTokenActivity(uint256 _tokenId) public;
}