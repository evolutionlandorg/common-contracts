pragma solidity ^0.4.24;

contract IInterstellarEncoder {
    uint256 public constant MAGIC_NUMBER = 42;    // Interstellar Encoding Magic Number.
    uint256 public constant CHAIN_ID = 1; // Ethereum mainet.
    uint256 public constant CURRENT_LAND = 1; // 1 is Atlantis, 0 is NaN.

    enum ObjectClass { 
        NaN,
        LAND,
        OBJECT_CLASS_COUNT
    }

    function encodeTokenId(address _tokenAddress, uint8 _objectClass, uint128 _objectIndex) public view returns (uint256 _tokenId);

    function getContractAddress(uint256 _tokenId) public view returns (address);
}