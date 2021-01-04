// Dependency file: openzeppelin-solidity/contracts/introspection/ERC165.sol

// pragma solidity ^0.4.24;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


// Root file: contracts/interfaces/IActivityObject.sol

pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/introspection/ERC165.sol";

contract IActivityObject is ERC165 {
    bytes4 internal constant InterfaceId_IActivityObject = 0x2b9eccc6; 
    /*
     * 0x2b9eccc6 ===
     *   bytes4(keccak256('activityAdded(uint256,address,address)')) ^ 
     *   bytes4(keccak256('activityRemoved(uint256,address,address)'))
     */

    function activityAdded(uint256 _tokenId, address _activity, address _user) public;

    function activityRemoved(uint256 _tokenId, address _activity, address _user) public;
}