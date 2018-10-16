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

    function getTokenLocation100M(uint256 _tokenId) public view returns (int, int){
        (int _x, int _y) = getTokenLocation(_tokenId);
        return ((_x + MAX_100M_DECIMAL)/HMETER_DECIMAL - MAX_100M, (_y + MAX_100M_DECIMAL)/HMETER_DECIMAL - MAX_100M);
    }

    function setTokenLocation100M(uint256 _tokenId, int _x, int _y) public{
        setTokenLocation(_tokenId, _x * HMETER_DECIMAL, _y * HMETER_DECIMAL);
    }


    function encodeLocationId100M(int _x, int _y) public pure  returns (uint result) {
        return encodeLocationId(_x * HMETER_DECIMAL, _y * HMETER_DECIMAL);
    }

    function encodeLocationId(int _x, int _y) public pure  returns (uint result) {
        return _unsafeEncodeLocationId(_x, _y);
    }

    function _unsafeEncodeLocationId(int _x, int _y) internal pure  returns (uint) {
        require(_x >= MIN_Location_XY && _x <= MAX_Location_XY, "Invalid value.");
        require(_y >= MIN_Location_XY && _y <= MAX_Location_XY, "Invalid value.");

        return (((uint(_x) * FACTOR) & CLEAR_LOW) | (uint(_y) & CLEAR_HIGH)) + 1;
    }

    function decodeLocationId100M(uint _positionId) public pure  returns (int, int) {
        (int _x, int _y) = decodeLocationId(_positionId);
        return ((_x + MAX_100M_DECIMAL)/HMETER_DECIMAL - MAX_100M, (_y + MAX_100M_DECIMAL)/HMETER_DECIMAL - MAX_100M);
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