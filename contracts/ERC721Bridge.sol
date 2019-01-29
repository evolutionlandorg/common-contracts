pragma solidity ^0.4.23;

import "./PausableDSAuth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./SettingIds.sol";
import "./interfaces/IInterstellarEncoderV3.sol";
import "./interfaces/IMintableERC20.sol";
import "./interfaces/INFTAdaptor.sol";
// import "./interfaces/IPetBase.sol";

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";


/*
 * naming convention:
 * originTokenId - token outside evolutionLand
 * mirrorTokenId - mirror token
 */
contract ERC721Bridge is SettingIds, PausableDSAuth {

    /*
     *  Storage
    */
    bool private singletonLock = false;

    ISettingsRegistry public registry;


    // originNFTContract => its adator
    // for instance, CryptoKitties => CryptoKittiesAdaptor
    // this need to be registered by owner
    mapping(address => address) public originNFT2Adaptor;

    // tokenId_inside => tokenId_outside
    mapping(uint256 => uint256) public mirrorId2OriginId;

    /*
    *  Event
    */
    event BridgeIn(uint256 originTokenId, uint256 mirrorTokenId, address originContract, address adaptorAddress, address owner);

    event SwapIn(uint256 originTokenId, uint256 mirrorTokenId, address owner);
    event SwapOut(uint256 originTokenId, uint256 mirrorTokenId, address owner);


    /*
    *  Modifiers
    */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract(ISettingsRegistry _registry) public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = _registry;
    }

    function registerAdaptor(address _originNftAddress, address _erc721Adaptor) public whenNotPaused onlyOwner {
        originNFT2Adaptor[_originNftAddress] = _erc721Adaptor;
    }

    // TODO: move this to PetBase.
    // function bridgeInAndTie(address _originNftAddress, uint256 _originTokenId, uint256 _apostleTokenId) public {
    //     uint256 mirrorTokenId = bridgeIn(_originNftAddress, _originTokenId);
    //     address petBase = registry.addressOf(SettingIds.CONTRACT_PET_BASE);
    //     IPetBase(petBase).tieMirrorTokenToApostle(mirrorTokenId, _apostleTokenId, msg.sender);
    // }

    // generate new mirror token without origin token frozen
    function bridgeIn(address _originNftAddress, uint256 _originTokenId) public returns (uint256) {
        address adaptor = originNFT2Adaptor[_originNftAddress];
        require(adaptor != address(0), "Not registered!");

        require(INFTAdaptor(adaptor).ownerInOrigin(_originTokenId) == msg.sender, "Invalid owner!");

        uint256 mirrorTokenId = INFTAdaptor(adaptor).toMirrorTokenId(_originTokenId);

        // if it is the first time to bridge in
        if (!isBridged(mirrorTokenId)) {
            // keep new mirror object in this contract
            // before the owner has transferred his/her outerObject into this contract
            // mirror object can not be transferred
            address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
            IMintableERC20(objectOwnership).mint(address(this), mirrorTokenId);

            // link objects_in and objects_out
            INFTAdaptor(adaptor).cacheMirrorTokenId(_originTokenId, mirrorTokenId);
            mirrorId2OriginId[mirrorTokenId] = _originTokenId;

            emit BridgeIn(_originTokenId, mirrorTokenId, _originNftAddress, adaptor, msg.sender);
        }

        return mirrorTokenId;
    }

    // freeze origin token to free mirror token
    function swapIn(address _originNftAddress, uint256 _originTokenId) public {
        require(ERC721(_originNftAddress).ownerOf(_originTokenId) == msg.sender, "Invalid owner!");

        address adaptor = originNFT2Adaptor[_originNftAddress];
        require(adaptor != address(0), "Not registered!");

        // all specific originTokens are kept in bridge
        ERC721(_originNftAddress).transferFrom(msg.sender, address(this), _originTokenId);

        uint256 mirrorTokenId = INFTAdaptor(adaptor).toMirrorTokenId(_originTokenId);
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        ERC721(objectOwnership).transferFrom(address(this), msg.sender, mirrorTokenId);

        emit SwapIn(_originTokenId, mirrorTokenId, msg.sender);
    }

    function bridgeAndSwapIn(address _originNftAddress, uint256 _originTokenId) public {
        bridgeIn(_originNftAddress, _originTokenId);
        swapIn(_originNftAddress, _originTokenId);
    }

    function swapOut(uint256 _mirrorTokenId) public  {
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        address nftContract = interstellarEncoder.getContractAddress(_mirrorTokenId);
        require(nftContract != address(0), "No such NFT contract");
        address adaptor = originNFT2Adaptor[nftContract];
        require(adaptor != address(0), "not registered!");
        require(ownerOfMirror(_mirrorTokenId) == msg.sender, "you have no right to swap it out!");

        // TODO: if it is needed to check its current status
        uint256 originTokenId = mirrorId2OriginId[_mirrorTokenId];
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        ERC721(objectOwnership).transferFrom(msg.sender, address(this), _mirrorTokenId);
        ERC721(nftContract).transferFrom(address(this), msg.sender, originTokenId);

        emit SwapOut(originTokenId, _mirrorTokenId, msg.sender);
    }

    function approveOriginToken(address _originNft, address _approved, uint256 _originTokenId) public auth {
        ERC721(_originNft).approve(_approved, _originTokenId);
    }

    function ownerOf(uint256 _mirrorTokenId) public view returns (address) {
        return ownerOfMirror(_mirrorTokenId);
    }

    // return human owner of the token
    function ownerOfOrigin(uint256 _originTokenId) public view returns (address) {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);

        INFTAdaptor adapter = INFTAdaptor(originNFT2Adaptor[originOwnershipAddress(mirrorTokenId)]);

        uint mirrorTokenId = adapter.toMirrorTokenId(_originTokenId);

        address owner = adapter.ownerInOrigin(_originTokenId);
        if(owner != address(this)) {
            return owner;
        } else {
            return ERC721(objectOwnership).ownerOf(mirrorTokenId);
        }
    }

    // return human owner of the token
    function ownerOfMirror(uint256 _mirrorTokenId) public view returns (address) {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        address owner = ERC721(objectOwnership).ownerOf(_mirrorTokenId);
        if(owner != address(this)) {
            return owner;
        } else {
            uint originTokenId = mirrorId2OriginId[_mirrorTokenId];
            return INFTAdaptor(originNFT2Adaptor[originOwnershipAddress(_mirrorTokenId)]).ownerInOrigin(originTokenId);
        }
    }

    function originOwnershipAddress(uint256 _mirrorTokenId) public view returns (address) {
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));

        return interstellarEncoder.getContractAddress(_mirrorTokenId);
    }

    function isBridged(uint256 _mirrorTokenId) public view returns (bool) {
        return (mirrorId2OriginId[_mirrorTokenId] != 0);
    }
}
