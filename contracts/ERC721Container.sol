pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/IInterstellarEncoder.sol";
import "./SettingIds.sol";

contract ERC721Container is Ownable, SettingIds {
    ISettingsRegistry public registry;

    // token ids must follow the standard of interstellar encoding
    mapping(uint256 => uint256[])   public objectsInContainer;

    mapping(uint256 => uint256)     public object2Container;

    mapping(uint256 => uint256)     public object2IndexInContainer;

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

    function contains(uint256 _containerTokenId, uint256 _objectTokenId) public view returns (bool) {
        require(_containerTokenId > 0, "Token Id should large than zero.");

        return object2Container[_objectTokenId] == _containerTokenId;
    }


    // TODO: does the add operation require the container's owner agree to?
    function addToContainer(uint256 _containerTokenId, uint256 _objectTokenId) public {
        // make sure this object is not already in container.
        require(object2Container[_objectTokenId] == 0, "Object Token can not be in container.");
        require(_containerTokenId > 0, "Token Id should large than zero.");

        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);
        require(interstellarEncoder != address(0), "Contract Interstellar Encoder does not exist.");

        address containerTokenAddress = IInterstellarEncoder(interstellarEncoder).getContractAddress(_containerTokenId);
        require(containerTokenAddress != address(0), "Container token contract is not registered.");
        address objectTokenAddress = IInterstellarEncoder(interstellarEncoder).getContractAddress(_objectTokenId);
        require(objectTokenAddress != address(0), "Object token contract is not registered.");

        address objectOwner = ERC721(objectTokenAddress).ownerOf(_objectTokenId);
        // requires approve first.
        ERC721(objectTokenAddress).transferFrom(objectOwner, address(this), _objectTokenId);

        // update belongs mappings.

        objectsInContainer[_containerTokenId].push(_objectTokenId);

        object2Container[_objectTokenId] = _containerTokenId;
        object2IndexInContainer[_objectTokenId] = objectsInContainer[_containerTokenId].length - 1;

    }

    function transferToOtherContainer(uint256 _objectTokenId, uint256 _toContainer) public {

    }

    function transferToAddress(uint256 _objectTokenId, address _receiver) public {
        (address _topOwner, address _topApproved) = getTopContainerOwnerAndApproved(_objectTokenId);

        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);
        require(interstellarEncoder != address(0), "Contract Interstellar Encoder does not exist.");

        address objectTokenAddress = IInterstellarEncoder(interstellarEncoder).getContractAddress(_objectTokenId);
        require(objectTokenAddress != address(0), "Object token contract is not registered.");
            
        if(_topOwner == msg.sender || _topApproved == msg.sender) {
            ERC721(objectTokenAddress).transferFrom(address(this), _receiver, _objectTokenId);
        }

        // Reorg index array in objectsInContainer
        uint256 objectIndex = object2IndexInContainer[_objectTokenId];
        uint256 lastObjectIndex = objectsInContainer[object2Container[_objectTokenId]].length - 1;
        uint256 lastObjectId = objectsInContainer[object2Container[_objectTokenId]][lastObjectIndex];

        objectsInContainer[object2Container[_objectTokenId]][objectIndex] = lastObjectId;
        objectsInContainer[object2Container[_objectTokenId]][lastObjectIndex] = 0;

        objectsInContainer[object2Container[_objectTokenId]].length --;
        object2IndexInContainer[lastObjectId] = objectIndex;
        
        delete object2Container[_objectTokenId];
        delete object2IndexInContainer[_objectTokenId];
    }

    function getTopContainerOwnerAndApproved(uint256 _objectTokenId) public view returns (address _owner, address _approved) {
        // make sure this object is already in container.
        require(object2Container[_objectTokenId] > 0, "Object Token can not be in container.");
        // recursive check to get authorized addresses to transfer.
        uint256 _topContainerTokenId = object2Container[_objectTokenId];
        while(object2Container[_topContainerTokenId] > 0) {
            _topContainerTokenId = object2Container[_topContainerTokenId];
        }

        address interstellarEncoder = registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER);
        require(interstellarEncoder != address(0), "Contract Interstellar Encoder does not exist.");

        _owner = ERC721(IInterstellarEncoder(interstellarEncoder).getContractAddress(_topContainerTokenId)).ownerOf(_topContainerTokenId);
        _approved = ERC721(IInterstellarEncoder(interstellarEncoder).getContractAddress(_topContainerTokenId))
            .getApproved(_topContainerTokenId);
    }

    function isContainer(uint256 _containerTokenId) public view returns (bool) {
        require(_containerTokenId > 0, "Token Id should large than zero.");

        return objectsInContainer[_containerTokenId].length > 0;
    }
}
