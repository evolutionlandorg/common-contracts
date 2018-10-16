pragma solidity ^0.4.24;

import "./RBACWithAuth.sol";
import "./interfaces/ITokenLocation.sol";

contract TokenLocation is RBACWithAuth, ITokenLocation {
    bool private singletonLock = false;

    // token id => encode(x,y) postiion in map
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
        return ((_x + MAX_100M_DECIMAL)/HMETER_DECIMAL - MAX_100M, (_y + MAX_100M_DECIMAL)/HMETER_DECIMAL - MAX_100M);
    }

    function setTokenLocationHM(uint256 _tokenId, int _x, int _y) public isAuth {
        setTokenLocation(_tokenId, _x * HMETER_DECIMAL, _y * HMETER_DECIMAL);
    }

    function encodeLocationIdHM(int _x, int _y) public pure  returns (uint result) {
        return encodeLocationId(_x * HMETER_DECIMAL, _y * HMETER_DECIMAL);
    }

    function decodeLocationIdHM(uint _positionId) public pure  returns (int, int) {
        (int _x, int _y) = decodeLocationId(_positionId);
        return ((_x + MAX_100M_DECIMAL)/HMETER_DECIMAL - MAX_100M, (_y + MAX_100M_DECIMAL)/HMETER_DECIMAL - MAX_100M);
    }

    function encodeLocationId(int _x, int _y) public pure  returns (uint result) {
        return _unsafeEncodeLocationId(_x, _y);
    }

    // decode tokenId to get (x,y)
    function getTokenLocation(uint256 _tokenId) public view returns (int, int) {
        uint locationId = tokenId2LocationId[_tokenId];
        return decodeLocationId(locationId);
    }

    function setTokenLocation(uint256 _tokenId, int _x, int _y) public isAuth {
        tokenId2LocationId[_tokenId] = encodeLocationId(_x, _y);
    }

    function _unsafeEncodeLocationId(int _x, int _y) internal pure  returns (uint) {
        require(_x >= MIN_Location_XY && _x <= MAX_Location_XY, "Invalid value.");
        require(_y >= MIN_Location_XY && _y <= MAX_Location_XY, "Invalid value.");

        return (((uint(_x) * FACTOR) & CLEAR_LOW) | (uint(_y) & CLEAR_HIGH)) + 1;
    }

    function decodeLocationId(uint _positionId) public pure  returns (int, int) {
        return _unsafeDecodeLocationId(_positionId);
    }

    function _unsafeDecodeLocationId(uint _value) internal pure  returns (int x, int y) {
        require(_value > 0, "Location Id is start from 1, should larger than zero");
        require(_value <= MAX_LOCATION_ID, "Location is larger than maximum.");
        x = expandNegative128BitCast(((_value - 1) & CLEAR_LOW) >> 124);
        y = expandNegative128BitCast((_value - 1) & CLEAR_HIGH);
    }

    function expandNegative128BitCast(uint _value) internal pure  returns (int) {
        if (_value & (1<<123) != 0) {
            return int(_value | APPEND_HIGH);
        }
        return int(_value);
    }
}