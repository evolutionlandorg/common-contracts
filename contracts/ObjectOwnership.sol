pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "./interfaces/IInterstellarEncoder.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./RBACWithAuth.sol";
import "./SettingIds.sol";

contract ObjectOwnership is ERC721Token("Evolution Land Objects","EVO"), RBACWithAuth, SettingIds {
    ISettingsRegistry public registry;

    bool private singletonLock = false;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    /**
     * @dev Guarantees msg.sender is owner of the given token
     * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
     */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

        /**
     * @dev Atlantis's constructor 
     */
    constructor () public {
        // initializeContract();
    }

    /**
     * @dev Same with constructor, but is used and called by storage proxy as logic contract.
     */
    function initializeContract(address _registry) public singletonLockCall {
        // Ownable constructor
        addRole(msg.sender, ROLE_ADMIN);
        addRole(msg.sender, ROLE_AUTH_CONTROLLER);

        // SupportsInterfaceWithLookup constructor
        _registerInterface(InterfaceId_ERC165);

        // ERC721BasicToken constructor
        _registerInterface(InterfaceId_ERC721);
        _registerInterface(InterfaceId_ERC721Exists);

        // ERC721Token constructor
        name_ = "Evolution Land Objects";
        symbol_ = "EVO";    // Evolution Land Objects
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(InterfaceId_ERC721Enumerable);
        _registerInterface(InterfaceId_ERC721Metadata);

        registry = ISettingsRegistry(_registry);
    }

    function mintObject(address _to, uint128 _objectId) public isAuth returns (uint256 _tokenId) {
        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);
        require(interstellarEncoder != address(0), "Contract Interstellar Encoder does not exist.");

        _tokenId = IInterstellarEncoder(interstellarEncoder).encodeTokenIdForObjectContract(
            address(this), msg.sender, _objectId);
        super._mint(_to, _tokenId);
    }

    function burnObject(address _to, uint128 _objectId) public isAuth returns (uint256 _tokenId) {
        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);
        require(interstellarEncoder != address(0), "Contract Interstellar Encoder does not exist.");

        _tokenId = IInterstellarEncoder(interstellarEncoder).encodeTokenIdForObjectContract(
            address(this), msg.sender, _objectId);
        super._burn(_to, _tokenId);
    }

    function mint(address _to, uint256 _tokenId) public isAuth {
        super._mint(_to, _tokenId);
    }

    function burn(address _to, uint256 _tokenId) public isAuth {
        super._burn(_to, _tokenId);
    }

    //@dev user invoke approveAndCall to create auction
    //@param _to - address of auction contractß
    function approveAndCall(
        address _to,
        uint _tokenId,
        bytes _extraData
    ) public onlyOwnerOf(_tokenId) {
        // set _to to the auction contract
        approve(_to, _tokenId);
        if(!_to.call(bytes4(keccak256("receiveApproval(address,uint256,bytes)")),
            abi.encode(msg.sender, _tokenId, _extraData))) {
            revert();
        }
    }
}
