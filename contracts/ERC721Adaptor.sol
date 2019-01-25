pragma solidity ^0.4.24;
import "./SettingIds.sol";
import "./PausableDSAuth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/INFTAdaptor.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IInterstellarEncoderV3.sol";


contract ERC721Adaptor is INFTAdaptor, PausableDSAuth, SettingIds {

    /*
     *  Storage
    */
    bool private singletonLock = false;

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
    event BridgeIn(uint256 originTokenId, uint256 tokenId, address originContract, address owner);


    /*
    *  Modifiers
    */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract(ISettingsRegistry _registry, INFTAdaptor _originNft) public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = _registry;
        originNft = _originNft;
    }



    function convertTokenId(uint256 _originTokenId) public auth returns (uint256) {
        require(tokenIdOut2In[_originTokenId] == 0);

        // first time to bridge in
        lastObjectId += 1;

        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        uint256 tokenId = interstellarEncoder.encodeTokenIdForOuterObjectContract(address(this), address(originNft), lastObjectId);

        // link objects_in and objects_out
        tokenIdOut2In[_originTokenId] = tokenId;
        tokenIdIn2Out[tokenId] = _originTokenId;

        return tokenId;
    }

    function approveToBridge(address _bridge) public onlyOwner {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        ERC721(objectOwnership).setApprovalForAll(_bridge, true);
    }


    function cancelApprove(address _bridge) public onlyOwner {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        ERC721(objectOwnership).setApprovalForAll(_bridge, false);
    }

    function ownerOf(uint256 _originTokenId) public view returns (address) {
        return originNft.ownerOf(_originTokenId);
    }

    function getObjectClass(uint256 _originTokenId) public view returns (uint8) {
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        uint256 tokenId = tokenIdOut2In[_originTokenId];
        return interstellarEncoder.getObjectClass(tokenId);
    }





}
