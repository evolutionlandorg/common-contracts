pragma solidity ^0.4.24;

contract ITokenUse {
    uint48 public constant MAX_UINT48_TIME = 281474976710655;

    function isObjectInHireStage(uint256 _tokenId) public view returns (bool);

    function isObjectReadyToUse(uint256 _tokenId) public view returns (bool);

    function getTokenUser(uint256 _tokenId) public view returns (address);

    function createTokenUseOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity) public;

    function cancelTokenUseOffer(uint256 _tokenId) public;

    function takeTokenUseOffer(uint256 _tokenId) public;

    function addActivity(uint256 _tokenId, address _user, uint256 _endTime) public;

    function removeActivity(uint256 _tokenId, address _user) public;
}