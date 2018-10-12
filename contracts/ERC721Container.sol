pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract ERC721Container is Ownable {

    // token ids must follow the standard of interstellar encoding
    mapping(uint256 => uint256[])   public objectsInContainer;

    mapping(uint256 => uint256)     public object2Container;

    mapping(uint256 => uint256)     public objectIndexInContainer;

    // Array with all container token ids, used for enumeration
    uint256[] internal allContainers;

    // Mapping from token id to position in the allContainers array
    mapping(uint256 => uint256) internal allContanerIndex;

    function contains(uint256 _containerTokenId, uint256 _objectTokenId) public view returns (bool) {
        require(_containerTokenId > 0, "Token Id should large than zero.");

        return object2Container[_objectTokenId] == _containerTokenId;
    }

    function addToContainer(uint256 _containerTokenId, uint256 _objectTokenId) public {

    }

    function moveToOtherContainer(uint256 _objectTokenId, uint256 _toContainer) public {

    }

    function moveToAddress(uint256 _objectTokenId, address _receiver) public {

    }

    function isContainer(uint256 _containerTokenId) public view returns (bool) {
        require(_containerTokenId > 0, "Token Id should large than zero.");

        return objectsInContainer[_containerTokenId].length > 0;
    }
}
