pragma solidity ^0.4.23;

import "./PausableDSAuth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./SettingIds.sol";
import "./interfaces/IInterstellarEncoderV3.sol";
import "./interfaces/IMintableERC20.sol";
import "./interfaces/INFTAdaptor.sol";
import "./interfaces/IPetBase.sol";

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
    mapping(address => address) public originNft2Adaptor;

    // tokenId_outside_evolutionLand => tokenId_inside
    mapping(uint256 => uint256) public tokenIdOut2In;

    // tokenId_inside => tokenId_outside
    mapping(uint256 => uint256) public tokenIdIn2Out;

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
        originNft2Adaptor[_originNftAddress] = _erc721Adaptor;
    }

    function bridgeInAndTie(address _originNftAddress, uint256 _originTokenId, uint256 _apostleTokenId) public {
        uint256 mirrorTokenId = bridgeIn(_originNftAddress, _originTokenId);
        address petBase = registry.addressOf(SettingIds.CONTRACT_PET_BASE);
        IPetBase(petBase).tieMirrorTokenToApostle(mirrorTokenId, _apostleTokenId, msg.sender);
    }

    // generate new mirror token without origin token frozen
    function bridgeIn(address _originNftAddress, uint256 _originTokenId) public returns (uint256){
        address adaptor = originNft2Adaptor[_originNftAddress];
        require(adaptor != address(0), 'not registered!');

        require(INFTAdaptor(adaptor).ownerInOrigin(_originTokenId) == msg.sender, "Invalid owner!");

        uint256 mirrorTokenId = tokenIdOut2In[_originTokenId];

        // if it is the first time to bridge in
        if (!isBridged(_originTokenId)) {
            require(tokenIdOut2In[_originTokenId] == 0, "already exists");

            mirrorTokenId = INFTAdaptor(adaptor).toMirrorTokenId(_originTokenId);
            // keep new mirror object in this contract
            // before the owner has transferred his/her outerObject into this contract
            // mirror object can not be transferred
            address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
            IMintableERC20(objectOwnership).mint(adaptor, mirrorTokenId);

            // link objects_in and objects_out
            tokenIdOut2In[_originTokenId] = mirrorTokenId;
            tokenIdIn2Out[mirrorTokenId] = _originTokenId;

            emit BridgeIn(_originTokenId, mirrorTokenId, _originNftAddress, adaptor, msg.sender);
        }

        return mirrorTokenId;
    }

    // freeze origin token to free mirror token
    function swapIn(address _originNftAddress, uint256 _originTokenId) public {
        require(ERC721(_originNftAddress).ownerOf(_originTokenId) == msg.sender, "Invalid owner!");
        address adaptor = originNft2Adaptor[_originNftAddress];
        require(adaptor != address(0), 'not registered!');

        // all specific originTokens are kept in their adaptor
        ERC721(_originNftAddress).transferFrom(msg.sender, adaptor, _originTokenId);
        INFTAdaptor(adaptor).approveOriginToken(address(this), _originTokenId);
        // mirror token of origin token
        // mirror tokens are kept in address(this)
        uint256 mirrorTokenId = tokenIdOut2In[_originTokenId];

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
        address nftContractAddress = interstellarEncoder.getContractAddress(_mirrorTokenId);
        require(nftContractAddress != address(0));
        address adaptor = originNft2Adaptor[nftContractAddress];
        require(adaptor != address(0), 'not registered!');
        require(ownerOfMirror(_mirrorTokenId) == msg.sender, "you have no right to swap it out!");

        // TODO: if it is needed to check its current status
        uint256 originTokenId = tokenIdIn2Out[_mirrorTokenId];
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        ERC721(objectOwnership).transferFrom(msg.sender, adaptor, _mirrorTokenId);
        ERC721(nftContractAddress).transferFrom(adaptor, msg.sender, originTokenId);

        emit SwapOut(originTokenId, _mirrorTokenId, msg.sender);
    }


    function ownerOf(uint256 _mirrorTokenId) public view returns (address) {
        return ownerOfMirror(_mirrorTokenId);
    }

    function ownerOfOrigin(uint256 _originTokenId) public view returns (address) {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        uint mirrorTokenId = tokenIdOut2In[_originTokenId];

        address owner = INFTAdaptor(originNft2Adaptor[originOwnershipAddress(mirrorTokenId)]).ownerInOrigin(_originTokenId);
        if(owner != address(this)) {
            return owner;
        } else {
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
            return INFTAdaptor(originNft2Adaptor[originOwnershipAddress(_mirrorTokenId)]).ownerInOrigin(originTokenId);
        }
    }

    function originOwnershipAddress(uint256 _mirrorTokenId) public view returns (address) {
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));

        return interstellarEncoder.getContractAddress(_mirrorTokenId);
    }

    function isBridged(uint256 _originTokenId) public view returns (bool) {
        if (tokenIdOut2In[_originTokenId] != 0) {
            return true;
        } else {
            return false;
        }
    }
}
