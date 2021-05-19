pragma solidity ^0.4.24;

contract IPetBase {
    function tiePetTokenToApostle(uint256 _mirrorTokenId, uint256 _apostleTokenId) public; 
    function pet2TiedStatus(uint256 _mirrorTokenId) public returns (uint256, uint256);
}
