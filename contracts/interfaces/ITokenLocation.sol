pragma solidity ^0.4.24;

contract ITokenLocation {

    bytes4 internal constant InterfaceId_ITokenLocationExists = 0x6033d48c;
    /*
    * 0x6033d48c ===
    *   bytes4(keccak256('getTokenLocation(uint256)'))
    */

    uint256 constant CLEAR_LOW =    0x00fffffffffffffffffffffffffffffff0000000000000000000000000000000;// <2, 31, 31> avoid overflow for add 1.
    uint256 constant CLEAR_HIGH =   0x000000000000000000000000000000000fffffffffffffffffffffffffffffff;// <2, 31, 31>
    uint256 constant APPEND_HIGH =  0xfffffffffffffffffffffffffffffffff0000000000000000000000000000000;
    uint256 constant MAX_LOCATION_ID =    0x0100000000000000000000000000000000000000000000000000000000000000;
    uint256 constant FACTOR = 0x10000000000000000000000000000000; // <16 ** 31> or <2 ** 124>

    // The location is in micron.
    function getTokenLocation(uint256 _tokenId) public view returns (int, int);

    function hasLocation(uint256 _tokenId) public view returns (bool);

    function setTokenLocation(uint256 _tokenId, int _x, int _y) public;

    function encodeLocationId(int _x, int _y) public pure  returns (uint result) {
        return _unsafeEncodeLocationId(_x, _y);
    }

    // x, y should between -2^123 (-10633823966279326983230456482242756608) and 2^123 - 1 (10633823966279326983230456482242756607).
    function _unsafeEncodeLocationId(int _x, int _y) internal pure  returns (uint) {
        require(_x >= -10633823966279326983230456482242756608 && _x <= 10633823966279326983230456482242756607, "Invalid value.");
        require(_y >= -10633823966279326983230456482242756608 && _y <= 10633823966279326983230456482242756607, "Invalid value.");
        
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