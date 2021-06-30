pragma solidity ^0.4.24;

import "./PausableDSAuth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./SettingIds.sol";
import "./interfaces/IInterstellarEncoderV3.sol";
import "./interfaces/IMintableERC20.sol";
import "./interfaces/IBurnableERC20.sol";
import "./interfaces/INFTAdaptor.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Receiver.sol";
import "./interfaces/IERC1155.sol";
import "./interfaces/IERC1155Receiver.sol";
import "./interfaces/IPetBase.sol";


/*
 * naming convention:
 * originTokenId - token outside evolutionLand
 * mirrorTokenId - mirror token
 */
contract ERC721BridgeV2 is SettingIds, PausableDSAuth, ERC721Receiver, IERC1155Receiver {

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

    mapping(uint256 => uint256) public mirrorId2OriginId1155;

    /*
     *  Event
     */
    // event BridgeIn(uint256 originTokenId, uint256 mirrorTokenId, address originContract, address adaptorAddress, address owner);

    event SwapIn(address originContract, uint256 originTokenId, uint256 mirrorTokenId, address owner);
    event SwapOut(address originContract, uint256 originTokenId, uint256 mirrorTokenId, address owner);

    function registerAdaptor(address _originNftAddress, address _erc721Adaptor) public whenNotPaused onlyOwner {
        originNFT2Adaptor[_originNftAddress] = _erc721Adaptor;
    }

    function swapOut721(uint256 _mirrorTokenId) public  {
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        address nftContract = interstellarEncoder.getOriginAddress(_mirrorTokenId);
        require(nftContract != address(0), "No such NFT contract");
        address adaptor = originNFT2Adaptor[nftContract];
        require(adaptor != address(0), "not registered!");
        require(ownerOfMirror(_mirrorTokenId) == msg.sender, "you have no right to swap it out!");

        address petBase = registry.addressOf(SettingIds.CONTRACT_PET_BASE);
        (uint256 apostleTokenId,) = IPetBase(petBase).pet2TiedStatus(_mirrorTokenId);
        require(apostleTokenId == 0, "Pet has been tied.");
        uint256 originTokenId = mirrorId2OriginId[_mirrorTokenId];
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        ERC721(objectOwnership).transferFrom(msg.sender, address(this), _mirrorTokenId);
        ERC721(nftContract).transferFrom(address(this), msg.sender, originTokenId);
        emit SwapOut(nftContract, originTokenId, _mirrorTokenId, msg.sender);
    }

	// V2 add - Support PolkaPet
    function swapOut1155(uint256 _mirrorTokenId) public  {
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        address nftContract = interstellarEncoder.getOriginAddress(_mirrorTokenId);
        require(nftContract != address(0), "No such NFT contract");
        address adaptor = originNFT2Adaptor[nftContract];
        require(adaptor != address(0), "not registered!");
        require(ownerOfMirror(_mirrorTokenId) == msg.sender, "you have no right to swap it out!");

        address petBase = registry.addressOf(SettingIds.CONTRACT_PET_BASE);
        (uint256 apostleTokenId,) = IPetBase(petBase).pet2TiedStatus(_mirrorTokenId);
        require(apostleTokenId == 0, "Pet has been tied.");
        uint256 originTokenId = mirrorId2OriginId1155[_mirrorTokenId];
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        IBurnableERC20(objectOwnership).burn(msg.sender, _mirrorTokenId);
        IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, originTokenId, 1, "");
        delete mirrorId2OriginId1155[_mirrorTokenId];
        emit SwapOut(nftContract, originTokenId, _mirrorTokenId, msg.sender);
    }

    function ownerOf(uint256 _mirrorTokenId) public view returns (address) {
        return ownerOfMirror(_mirrorTokenId);
    }

    // return human owner of the token
    function mirrorOfOrigin(address _originNFT, uint256 _originTokenId) public view returns (uint256) {
        INFTAdaptor adapter = INFTAdaptor(originNFT2Adaptor[_originNFT]);

        return adapter.toMirrorTokenId(_originTokenId);
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

        return interstellarEncoder.getOriginAddress(_mirrorTokenId);
    }

    function isBridged(uint256 _mirrorTokenId) public view returns (bool) {
        return (mirrorId2OriginId[_mirrorTokenId] != 0);
    }

    // V2 add - Support PolkaPet
    function swapIn1155(address _originNftAddress, uint256 _originTokenId, uint256 _value) public whenNotPaused() {
        address _from = msg.sender;
        IERC1155(_originNftAddress).safeTransferFrom(_from, address(this), _originTokenId, _value, "");
        address adaptor = originNFT2Adaptor[_originNftAddress];
        require(adaptor != address(0), "Not registered!");
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        for (uint256 i = 0; i < _value; i++) {
            uint256 mirrorTokenId = INFTAdaptor(adaptor).toMirrorTokenIdAndIncrease(_originTokenId);
            IMintableERC20(objectOwnership).mint(_from, mirrorTokenId);
            mirrorId2OriginId1155[mirrorTokenId] = _originTokenId;
            // emit BridgeIn(_originTokenId, mirrorTokenId, _originNftAddress, adaptor, _from);
            emit SwapIn(_originNftAddress, _originTokenId, mirrorTokenId, _from);
        }
    }

    function swapIn721(address _originNftAddress, uint256 _originTokenId) public whenNotPaused() {
        address _owner = msg.sender;
        ERC721(_originNftAddress).transferFrom(_owner, address(this), _originTokenId);
        address adaptor = originNFT2Adaptor[_originNftAddress];
        require(adaptor != address(0), "Not registered!");
        uint256 mirrorTokenId = INFTAdaptor(adaptor).toMirrorTokenId(_originTokenId);
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        if (!isBridged(mirrorTokenId)) {
            IMintableERC20(objectOwnership).mint(address(this), mirrorTokenId);
            INFTAdaptor(adaptor).cacheMirrorTokenId(_originTokenId, mirrorTokenId);
            mirrorId2OriginId[mirrorTokenId] = _originTokenId;
            // emit BridgeIn(_originTokenId, mirrorTokenId, _originNftAddress, adaptor, _owner);
        }
        ERC721(objectOwnership).transferFrom(address(this), _owner, mirrorTokenId);
        emit SwapIn(_originNftAddress, _originTokenId, mirrorTokenId, _owner);
    }

    function onERC721Received(
      address /*_operator*/,
      address /*_from*/,
      uint256 /*_tokenId*/,
      bytes /*_data*/
    )
      external 
      returns(bytes4) 
    {
        return ERC721_RECEIVED;
    }

    function onERC1155Received(
      address /*operator*/,
      address /*from*/,
      uint256 /*id*/,
      uint256 /*value*/,
      bytes /*data*/
    )
      external
      returns(bytes4)
    {
        return ERC1155_RECEIVED_VALUE; 
    }

    function onERC1155BatchReceived(
      address /*operator*/,
      address /*from*/,
      uint256[] /*ids*/,
      uint256[] /*values*/,
      bytes /*data*/
    )
      external
      returns(bytes4)
    {
        return ERC1155_BATCH_RECEIVED_VALUE;	
    }
}
