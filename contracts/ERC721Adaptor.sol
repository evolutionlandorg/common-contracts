pragma solidity ^0.4.24;

import "./SettingIds.sol";
import "./PausableDSAuth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/INFTAdaptor.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IInterstellarEncoderV3.sol";


contract ERC721Adaptor is PausableDSAuth, SettingIds {

    /*
     *  Storage
    */
    bool private singletonLock = false;

    uint16 public producerId;

    ISettingsRegistry public registry;

    ERC721 public originNft;

    uint128 public lastObjectId;

    // tokenId_outside_evolutionLand => tokenId_inside
    mapping(uint256 => uint256) public tokenIdOut2In;

    // tokenId_inside => tokenId_outside
    mapping(uint256 => uint256) public tokenIdIn2Out;



    /*
    *  Event
    */
    event BridgeIn(uint256 originTokenId, uint256 mirrorTokenId, address originContract, address owner);


    /*
    *  Modifiers
    */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract(ISettingsRegistry _registry, ERC721 _originNft, uint16 _producerId) public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = _registry;
        originNft = _originNft;
        producerId = _producerId;
    }


    function convertTokenId(uint256 _originTokenId) public auth returns (uint256) {

        require(tokenIdOut2In[_originTokenId] == 0, "already exists");
        // first time to bridge in
        lastObjectId += 1;

        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        address petBase = registry.addressOf(SettingIds.CONTRACT_PET_BASE);
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        uint256 mirrorTokenId = interstellarEncoder.encodeTokenIdForOuterObjectContract(petBase, objectOwnership, address(originNft), lastObjectId, producerId);

        // link objects_in and objects_out
        tokenIdOut2In[_originTokenId] = mirrorTokenId;
        tokenIdIn2Out[mirrorTokenId] = _originTokenId;

        return mirrorTokenId;


    }

    function approveToBridge(address _bridge) public onlyOwner {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        ERC721(objectOwnership).setApprovalForAll(_bridge, true);
    }


    function cancelApprove(address _bridge) public onlyOwner {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        ERC721(objectOwnership).setApprovalForAll(_bridge, false);
    }

    function approveOriginToken(address _bridge, uint256 _originTokenId) public auth {
        ERC721(originNft).approve(_bridge, _originTokenId);
    }

    function ownerOfOrigin(uint256 _originTokenId) public view returns (address) {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        address owner = ERC721(originNft).ownerOf(_originTokenId);
        if(owner != address(this)) {
            return owner;
        } else {
            uint mirrorTokenId = tokenIdIn2Out[_originTokenId];
            return ERC721(objectOwnership).ownerOf(mirrorTokenId);
        }
    }

    function ownerOfMirror(uint256 _mirrorTokenId) public view returns (address) {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        address owner = ERC721(objectOwnership).ownerOf(_mirrorTokenId);
        if(owner != address(this)) {
            return owner;
        } else {
            uint originTokenId = tokenIdIn2Out[_mirrorTokenId];
            return originNft.ownerOf(originTokenId);
        }
    }


    function isBridged(uint256 _originTokenId) public view returns (bool) {
        if (tokenIdOut2In[_originTokenId] != 0) {
            return true;
        } else {
            return false;
        }
    }

    function getObjectClass(uint256 _originTokenId) public view returns (uint8) {
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        uint256 mirrorTokenId = tokenIdOut2In[_originTokenId];
        return interstellarEncoder.getObjectClass(mirrorTokenId);
    }



}
