pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

// TODO: upgrade.
contract EncoderTemplate is Ownable {

    uint256 constant CLEAR_HIGH =  0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    uint256 public constant MAGIC_NUMBER = 42;    // Interstellar Encoding Magic Number.
    uint8 public constant OBJECT_CLASS = 1;
    uint256 public constant CHAIN_ID = 1; // Ethereum mainet.
    uint256 public constant CURRENT_LAND = 13; // random number, will be decided later

    // [magic_number, chain_id, contract_id <2>, origin_chain_id, origin_contract_id<2>, object_class, convert_type, <6>, land, <128>]
    mapping(uint8 => address) public ownershipId2Address;
    mapping(address => uint8) public ownershipAddress2Id;

    mapping(address => uint8) public classAddress2Id;   // class
    // extended since V2
    mapping(uint8 => address) public classId2Address;
    

    function encodeTokenId(address _tokenAddress, uint128 _objectId) public view returns (uint256 _tokenId) {
        uint16 contractId = ownershipAddress2Id[_tokenAddress];
        require(ownershipAddress2Id[_tokenAddress] > 0, "Contract address does not exist");

        _tokenId = (MAGIC_NUMBER << 248) + (CHAIN_ID << 240) + (uint256(contractId) << 224)
            + (CHAIN_ID << 216) + (uint256(contractId) << 200) + (uint256(OBJECT_CLASS) << 192) + (CURRENT_LAND << 128) + uint256(_objectId);
    }

    function encodeTokenIdAuth(address _tokenAddress, uint8 _objectClass, uint256 _producerId, uint128 _objectId) public view returns (uint256 _tokenId) {
        uint16 contractId = ownershipAddress2Id[_tokenAddress];
        require(ownershipAddress2Id[_tokenAddress] > 0, "Contract address does not exist");

        _tokenId = (MAGIC_NUMBER << 248) + (CHAIN_ID << 240) + (uint256(contractId) << 224)
        + (CHAIN_ID << 216) + (uint256(contractId) << 200) + (uint256(_objectClass) << 192) + (_producerId << 128) + uint256(_objectId);
    }



    function registerNewOwnershipContract(address _nftAddress, uint8 _nftId) public onlyOwner {
        ownershipAddress2Id[_nftAddress] = _nftId;
        ownershipId2Address[_nftId] = _nftAddress;
    }

    function registerNewObjectClass(address _objectContract, uint8 _objectClass) public onlyOwner {
        classAddress2Id[_objectContract] = _objectClass;
        classId2Address[_objectClass] = _objectContract;
    }

    function getProducerId(uint256 _tokenId) public view returns (uint16) {
        return uint16((_tokenId >> 128) & 0xff);
    }

    function getContractAddress(uint256 _tokenId) public view returns (address) {
        return ownershipId2Address[uint8((_tokenId >> 240) & 0xff)];
    }

    function getObjectId(uint256 _tokenId) public view returns (uint128 _objectId) {
        return uint128(_tokenId & CLEAR_HIGH);
    }

    function getObjectClass(uint256 _tokenId) public view returns (uint8) {
        return uint8((_tokenId << 56) >> 248);
    }

    function getObjectAddress(uint256 _tokenId) public view returns (address) {
        return classId2Address[uint8((_tokenId << 56) >> 248)];
    }

    // TODO; newly added
    function getOriginAddress(uint256 _tokenId) public view returns (address) {
        uint8 originContractId = uint8((_tokenId >> 200) & 0xff);
        return ownershipId2Address[originContractId];

    }
}