pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract INFTAdaptor is ERC721 {
    function convertTokenId(uint256 _originTokenId) public returns (uint256);

    function tokenIdOut2In(uint256 _originTokenId) public view returns (uint256);

}
