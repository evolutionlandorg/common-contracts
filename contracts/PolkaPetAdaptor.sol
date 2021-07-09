pragma solidity ^0.4.24;

import "./SettingIds.sol";
import "./PausableDSAuth.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/IInterstellarEncoderV3.sol";


contract PolkaPetAdaptor is PausableDSAuth, SettingIds {

	event SetTokenIDAuth(uint256 indexed tokenId, bool status);

    /*
     *  Storage
    */

    uint16 public producerId;

    uint8 public convertType;

    ISettingsRegistry public registry;

    address public originNft;

	uint128 public lastObjectId;

	// tokenID => bool allowList
    mapping (uint256 => bool) public allowList;

    constructor(ISettingsRegistry _registry, address _originNft, uint16 _producerId) public {
        registry = _registry;
        originNft = _originNft;
        producerId = _producerId;
        convertType = 128;  // f(x) = x，fullfill with zero at left side.

        allowList[2] = true;   // Darwinia
        allowList[11] = true;  // EVO
        allowList[20] = true;  // Crab
    }

	function setTokenIDAuth(uint256 _tokenId, bool _status) public auth {
		allowList[_tokenId] = _status;
		emit SetTokenIDAuth(_tokenId, _status);	
	}

    function toMirrorTokenIdAndIncrease(uint256 _originTokenId) public auth returns (uint256) {
		require(allowList[_originTokenId], "POLKPET: PERMISSION");
        lastObjectId += 1;
		require(lastObjectId < uint128(-1), "POLKPET: OBJECTID_OVERFLOW");
        uint128 mirrorObjectId = uint128(lastObjectId & 0xffffffffffffffffffffffffffffffff);
        address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
        address petBase = registry.addressOf(SettingIds.CONTRACT_PET_BASE);
        IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
        uint256 mirrorTokenId = interstellarEncoder.encodeTokenIdForOuterObjectContract(
            petBase, objectOwnership, originNft, mirrorObjectId, producerId, convertType);

        return mirrorTokenId;
    }

}
