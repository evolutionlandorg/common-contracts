pragma solidity ^0.4.24;

contract ITokenUse {
    function isObjectInUseStage(uint256 _tokenId) public view returns (bool);

    function getTokenOwner(uint256 _tokenId) public view returns (address);

    function getTokenUser(uint256 _tokenId) public view returns (address);

    function createTokenUseOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity) public;

    function cancelTokenUseOffer(uint256 _tokenId) public;

    function takeTokenUseOffer(uint256 _tokenId) public;

    function startTokenUseFromActivity(
        uint256 _tokenId, address _user, address _owner, uint256 _startTime, uint256 _endTime, uint256 _price) public;

    function stopTokenUseFromActivity(uint256 _tokenId) public;

    function removeTokenUse(uint256 _tokenId) public;
}