pragma solidity ^0.4.24;

import "./interfaces/ITokenLocation.sol";
import "./RBACWithAuth.sol";
import "./LocationCoder.sol";

contract TokenLocation is RBACWithAuth, ITokenLocation {
    bool private singletonLock = false;

    // token id => encode(x,y) postiion in map, the location is in micron.
    mapping (uint256 => uint256) public tokenId2LocationId;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract() public singletonLockCall {
        // Ownable constructor
        addRole(msg.sender, ROLE_ADMIN);
        addRole(msg.sender, ROLE_AUTH_CONTROLLER);
    }

    function hasLocation(uint256 _tokenId) public view returns (bool) {
        return tokenId2LocationId[_tokenId] != 0;
    }

    function getTokenLocationHM(uint256 _tokenId) public view returns (int, int){
        (int _x, int _y) = getTokenLocation(_tokenId);
        return (LocationCoder.toHM(_x), LocationCoder.toHM(_y));
    }

    function setTokenLocationHM(uint256 _tokenId, int _x, int _y) public isAuth {
        setTokenLocation(_tokenId, LocationCoder.toUM(_x), LocationCoder.toUM(_y));
    }

    // decode tokenId to get (x,y)
    function getTokenLocation(uint256 _tokenId) public view returns (int, int) {
        uint locationId = tokenId2LocationId[_tokenId];
        return LocationCoder.decodeLocationIdXY(locationId);
    }

    function setTokenLocation(uint256 _tokenId, int _x, int _y) public isAuth {
        tokenId2LocationId[_tokenId] = LocationCoder.encodeLocationIdXY(_x, _y);
    }
}