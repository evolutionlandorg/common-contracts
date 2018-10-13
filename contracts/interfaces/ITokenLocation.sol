pragma solidity ^0.4.24;

contract ITokenLocation {

    bytes4 internal constant InterfaceId_ITokenLocationExists = 0x6033d48c;
    /*
    * 0x6033d48c ===
    *   bytes4(keccak256('getTokenLocation(uint256)'))
    */

    uint256 constant CLEAR_LOW = 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
    uint256 constant CLEAR_HIGH = 0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    uint256 constant FACTOR = 0x100000000000000000000000000000000;

    // virtual api
    function getTokenLocation(uint256 _tokenId) public view returns (int, int);

    function hasLocation(uint256 _tokenId) public view returns (bool);

    function setTokenLocation(uint256 _tokenId, int _x, int _y) public;

    function encodeLocationId(int _x, int _y) public pure  returns (uint result) {
        return _unsafeEncodeLocationId(_x, _y);
    }

    function _unsafeEncodeLocationId(int _x, int _y) internal pure  returns (uint) {
        return ((uint(_x) * FACTOR) & CLEAR_LOW) | (uint(_y) & CLEAR_HIGH) + 1;
    }

    function decodeLocationId(uint _positionId) public pure  returns (int, int) {
        return _unsafeDecodeLocationId(_positionId);
    }

    function _unsafeDecodeLocationId(uint _value) internal pure  returns (int x, int y) {
        require(_value > 0, "Location Id is start from 1, should larger than zero");
        x = expandNegative128BitCast(((_value - 1) & CLEAR_LOW) >> 128);
        y = expandNegative128BitCast((_value - 1) & CLEAR_HIGH);
    }

    function expandNegative128BitCast(uint _value) internal pure  returns (int) {
        if (_value & (1<<127) != 0) {
            return int(_value | CLEAR_LOW);
        }
        return int(_value);
    }

}