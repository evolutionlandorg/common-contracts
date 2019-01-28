pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./interfaces/IInterstellarEncoder.sol";

// TODO: upgrade.
contract InterstellarEncoderV3 is IInterstellarEncoder, Ownable {
    // [magic_number, chain_id, contract_id <2>, origin_chain_id, origin_contract_id<2>, object_class, convert_type, <6>, land, <128>]
    mapping(uint16 => address) public contractId2Address;
    mapping(address => uint16) public contractAddress2Id;

    mapping(address => uint8) public objectContract2ObjectClass;

    uint16 public lastContractId = 0;

    // extended since V2
    mapping(uint8 => address) public objectClass2ObjectContract;

    function encodeTokenId(address _tokenAddress, uint8 _objectClass, uint128 _objectId) public view returns (uint256 _tokenId) {
        uint16 contractId = contractAddress2Id[_tokenAddress];
        require(contractAddress2Id[_tokenAddress] > 0, "Contract address does not exist");

        _tokenId = (MAGIC_NUMBER << 248) + (CHAIN_ID << 240) + (uint256(contractId) << 224)
            + (CHAIN_ID << 216) + (uint256(contractId) << 200) + (uint256(_objectClass) << 192) + (CURRENT_LAND << 128) + uint256(_objectId);
    }

    function encodeTokenIdForOuter(address _objectContract, address _nftAddress, address _originNftAddress, uint8 _objectClass, uint128 _objectId, uint16 _producerId) public view returns (uint256) {
        uint16 contractId = contractAddress2Id[_nftAddress];
        uint16 originContractId = contractAddress2Id[_originNftAddress];
        require( contractId > 0 && originContractId > 0 && _producerId > 0, "Contract address does not exist");

        uint256 tokenId = (MAGIC_NUMBER << 248) + (CHAIN_ID << 240) + (uint256(contractId) << 224)
        + (CHAIN_ID << 216) + (uint256(originContractId) << 200) + (uint256(_objectClass) << 192) + (uint256(_producerId) << 128) + uint256(_objectId);

        return tokenId;
    }

    // TODO; newly added
    // @param _tokenAddress - objectOwnership
    // @param _objectContract - xxxBase contract
    function encodeTokenIdForOuterObjectContract(address _objectContract, address _nftAddress, address _originNftAddress, uint128 _objectId, uint16 _producerId) public view returns (uint256) {
        require (objectContract2ObjectClass[_objectContract] > 0, "Object class for this object contract does not exist.");

        return encodeTokenIdForOuter(_objectContract,_nftAddress, _originNftAddress, objectContract2ObjectClass[_objectContract], _objectId, _producerId);

    }
    // TODO; newly added
    function encodeTokenIdForObjectContract(
        address _tokenAddress, address _objectContract, uint128 _objectId) public view returns (uint256 _tokenId) {
        require (objectContract2ObjectClass[_objectContract] > 0, "Object class for this object contract does not exist.");

        _tokenId = encodeTokenId(_tokenAddress, objectContract2ObjectClass[_objectContract], _objectId);
    }

    function registerNewTokenContract(address _tokenAddress) public onlyOwner {
        require(contractAddress2Id[_tokenAddress] == 0, "Contract address already exist");
        require(lastContractId < 65535, "Contract Id already reach maximum.");

        lastContractId += 1;

        contractAddress2Id[_tokenAddress] = lastContractId;
        contractId2Address[lastContractId] = _tokenAddress;
    }

    function registerNewObjectClass(address _objectContract, uint8 _objectClass) public onlyOwner {
        objectContract2ObjectClass[_objectContract] = _objectClass;
        objectClass2ObjectContract[_objectClass] = _objectContract;
    }


    function getContractAddress(uint256 _tokenId) public view returns (address) {
        return contractId2Address[uint16((_tokenId << 16) >> 240)];
    }

    function getObjectId(uint256 _tokenId) public view returns (uint128 _objectId) {
        return uint128(_tokenId & CLEAR_HIGH);
    }

    function getObjectClass(uint256 _tokenId) public view returns (uint8) {
        return uint8((_tokenId << 56) >> 248);
    }

    function getObjectAddress(uint256 _tokenId) public view returns (address) {
        return objectClass2ObjectContract[uint8((_tokenId << 56) >> 248)];
    }

    // TODO; newly added
    function getOriginAddress(uint256 _tokenId) public view returns (address) {
        uint16 originContractId = uint16((_tokenId >> 200) & 0xffff);
        return contractId2Address[originContractId];

    }
}