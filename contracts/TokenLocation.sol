pragma solidity ^0.4.24;

import "./RBACWithAuth.sol";
import "./interfaces/ITokenLocation.sol";

contract TokenLocation is RBACWithAuth, ITokenLocation {
    // token id => encode(x,y) postiion in map
    mapping (uint256 => uint256) public tokenId2LocationId;

        // decode tokenId to get (x,y)
    function getTokenLocation(uint256 _tokenId) public view returns (int, int) {
        uint locationId = tokenId2LocationId[_tokenId];
        return decodeLocationId(locationId);
    }

    function setTokenLocation(uint256 _tokenId, int _x, int _y) public isAuth {
        tokenId2LocationId[_tokenId] = encodeLocationId(_x, _y);
        
    }

    function hasLocation(uint256 _tokenId) public view returns (bool) {
        return tokenId2LocationId[_tokenId] != 0;
    }
}