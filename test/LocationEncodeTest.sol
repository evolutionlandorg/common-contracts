pragma solidity ^0.4.24;

contract LocationEncodeTest {
    
    uint256 constant FACTOR = 0x100000000000000000000000000000000;
    
    function test0() public pure returns (bytes32) {
        return bytes32(uint(-2));
    }
    
    function test1() public pure returns (bytes32) {
        return bytes32(uint(-2) * FACTOR);
    }
    
    function test2() public pure returns (bytes32) {
        return bytes32(uint(2) * FACTOR);
    }
    
    function test3() public pure returns (bytes32) {
        return bytes32(int(uint(-2)));
    }
}