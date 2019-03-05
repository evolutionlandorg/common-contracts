pragma solidity ^0.4.23;

contract IEncoder {
    function encodeTokenId(address _tokenAddress, uint128 _objectId) public view returns (uint256);

    function encodeTokenIdAuth(address _tokenAddress, uint8 _objectClass, uint256 _producerId, uint128 _objectId) public view returns (uint256);

    function OBJECT_CLASS() public view returns (uint8);

    function CURRENT_LAND() public view returns (uint256);
}
