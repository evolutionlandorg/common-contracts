pragma solidity ^0.4.23;

import "./PausableDSAuth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./SettingIds.sol";
import "./interfaces/IInterstellarEncoderV3.sol";
import "./interfaces/IMintableERC20.sol";
import "./interfaces/INFTAdaptor.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";


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

    /*
    *  Event
    */
    event BridgeIn(uint256 originTokenId, uint256 tokenId, address originContract, address adaptorAddress, address owner);

    event SwapIn(uint256 originTokenId, uint256 tokenId, address owner);


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
    }

    function registerAdaptor(address _originNftAddress, address _erc721Adaptor) public whenNotPaused onlyOwner {
        originNft2Adaptor[_originNftAddress] = _erc721Adaptor;
    }


    // generate new mirror token without origin token frozen
    function bridgeIn(address _originNftAddress, uint256 _originTokenId) public {
        require(ERC721(_originNftAddress).ownerOf(_originTokenId) == msg.sender, "Invalid owner!");
        address adaptor = originNft2Adaptor[_originNftAddress];
        require(adaptor != address(0), 'not registered!');

        uint256 tokenId = INFTAdaptor(adaptor).convertTokenId(_originTokenId);
        // keep new mirror object in this contract
        // before the owner has transferred his/her outerObject into this contract
        // mirror object can not be transferred
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        IMintableERC20(objectOwnership).mint(address(this), tokenId);


        emit BridgeIn(_originTokenId, tokenId, _originNftAddress, adaptor, msg.sender);
    }

    // freeze origin token to free mirror token
    function swapIn(address _originNftAddress, uint256 _originTokenId) public {
        require(ERC721(_originNftAddress).ownerOf(_originTokenId) == msg.sender, "Invalid owner!");
        address adaptor = originNft2Adaptor[_originNftAddress];
        require(adaptor != address(0), 'not registered!');

        // all specific originTokens are kept in their adaptor
        ERC721(_originNftAddress).transferFrom(msg.sender, adaptor, _originTokenId);
        // mirror token of origin token
        // mirror tokens are kept in address(this)
        uint256 tokenId =  INFTAdaptor(adaptor).tokenIdOut2In(_originTokenId);

        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        ERC721(objectOwnership).transferFrom(address(this), msg.sender, tokenId);

        emit SwapIn(_originTokenId, tokenId, msg.sender);
    }



}
