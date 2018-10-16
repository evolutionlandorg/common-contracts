pragma solidity ^0.4.24;

contract IObjectOwnership {
    function mintObject(address _to, uint128 _objectId) public returns (uint256 _tokenId);

    function burnObject(address _to, uint128 _objectId) public returns (uint256 _tokenId);
}