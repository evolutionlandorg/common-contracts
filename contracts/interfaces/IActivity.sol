pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/introspection/ERC165.sol";

contract IActivity is ERC165 {
    bytes4 internal constant InterfaceId_IActivity = 0x8fc0f454; 
    /*
     * 0x8fc0f454 ===
     *   bytes4(keccak256('tokenUseStopped(uint256)'))
     */

    function tokenUseStopped(uint256 _tokenId) public;
}