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

    int256 constant public HMETER_DECIMAL  = 10 ** 8;

    // x, y should between -2^123 (-10633823966279326983230456482242756608) and 2^123 - 1 (10633823966279326983230456482242756607).
    int256 constant public MIN_Location_XY = -10633823966279326983230456482242756608;
    int256 constant public MAX_Location_XY = 10633823966279326983230456482242756607;
    // 106338239662793269832304564823.5
    int256 constant public MAX_100M_DECIMAL  = 10633823966279326983230456482350000000;
    int256 constant public MAX_100M  = 106338239662793269832304564823;

    function hasLocation(uint256 _tokenId) public view returns (bool);

    // The location is in micron.

    function getTokenLocation100M(uint256 _tokenId) public view returns (int, int);

    function setTokenLocation100M(uint256 _tokenId, int _x, int _y);

    function getTokenLocation(uint256 _tokenId) public view returns (int, int);

    function setTokenLocation(uint256 _tokenId, int _x, int _y) public;

    function encodeLocationId100M(int _x, int _y) public pure  returns (uint result);

    function encodeLocationId(int _x, int _y) public pure  returns (uint result);

    function decodeLocationId100M(uint _positionId) public pure  returns (int, int);

    function decodeLocationId(uint _positionId) public pure  returns (int, int);


}