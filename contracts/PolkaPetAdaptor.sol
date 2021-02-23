pragma solidity ^0.4.24;

import "./SettingIds.sol";
import "./PausableDSAuth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/INFTAdaptor.sol";
// import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IInterstellarEncoderV3.sol";
import "./interfaces/IERC1155.sol";


contract PolkaPetAdaptor is PausableDSAuth, SettingIds {

	event SetTokenIDAuth(uint256 indexed tokenId, bool status);

    /*
     *  Storage
    */
    bool private singletonLock = false;

    uint16 public producerId;

    uint8 public convertType;

    ISettingsRegistry public registry;

    IERC1155 public originNft;

	uint128 public lastObjectId;

	// tokenID => bool allowList
    mapping (uint256 => bool) public allowList;

    /*
    *  Modifiers
    */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract(ISettingsRegistry _registry, IERC1155 _originNft, uint16 _producerId) public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = _registry;
        originNft = _originNft;
        producerId = _producerId;

        convertType = 128;  // f(x) = x，fullfill with zero at left side.
    }

	function setTokenIDAuth(uint256 _tokenId, bool _status) public auth {
		allowList[_tokenId] = _status;
		emit SetTokenIDAuth(_tokenId, _status);	
	}

    function toMirrorTokenIdAndIncrease(uint256 _originTokenId) public returns (uint256) {
		require(allowList[_originTokenId], "POLKPET: PERMISSION");
        lastObjectId += 1;
        uint128 mirrorObjectId = uint128(lastObjectId & 0xffffffffffffffffffffffffffffffff);
		require(lastObjectId <= uint128(-1), "POLKPET: OBJECTID_OVERFLOW");
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        address petBase = registry.addressOf(SettingIds.CONTRACT_PET_BASE);
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        uint256 mirrorTokenId = interstellarEncoder.encodeTokenIdForOuterObjectContract(
            petBase, objectOwnership, address(originNft), mirrorObjectId, producerId, convertType);

        return mirrorTokenId;
    }

    function ownerInOrigin(uint256 _originTokenId) public view returns (address) {
		revert("NOT_SUPPORT");
    }

    // if the convertion is not calculatable, and need to use cache mapping in Bridge.
    // then ..
    function toOriginTokenId(uint256 _mirrorTokenId) public view returns (uint256) {
		revert("NOT_SUPPORT");
    }

    function approveToBridge(address _bridge) public onlyOwner {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        IERC1155(objectOwnership).setApprovalForAll(_bridge, true);
    }

    function cancelApprove(address _bridge) public onlyOwner {
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        IERC1155(objectOwnership).setApprovalForAll(_bridge, false);
    }

    function getObjectClass(uint256 _originTokenId) public view returns (uint8) {
		revert("NOT_SUPPORT");
    }

    function cacheMirrorTokenId(uint256 _originTokenId, uint256 _mirrorTokenId) public auth {
		revert("NOT_SUPPORT");
    }
}
