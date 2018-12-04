pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/introspection/ERC165.sol";

contract IMiner is ERC165  {
    bytes4 internal constant InterfaceId_IActivity = 0x5822a422; 
    /*
     * 0x5822a422 ===
     *   bytes4(keccak256('strengthOf(uint256)'))
     */

    function strengthOf(uint256 _tokenId) public view returns (uint);

}