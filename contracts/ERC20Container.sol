pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/IInterstellarEncoder.sol";
import "./SettingIds.sol";

contract ERC20Container is Ownable, SettingIds {
    ISettingsRegistry public registry;

    // token ids must follow the standard of interstellar encoding
    mapping(uint256 => mapping(address=>uint256))   public fungibleTokensInContainer;

    bool private singletonLock = false;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    constructor () public {
        // initializeContract();
    }

        /**
     * @dev Same with constructor, but is used and called by storage proxy as logic contract.
     */
    function initializeContract(address _registry) public singletonLockCall {
        // Ownable constructor
        owner = msg.sender;

        registry = ISettingsRegistry(_registry);
    }
}