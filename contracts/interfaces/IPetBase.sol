pragma solidity ^0.4.24;

interface IPetBase {
    function tiePetTokenToApostle(uint256 _mirrorTokenId, uint256 _apostleTokenId) external;
    function pet2TiedStatus(uint256 _mirrorTokenId) external returns (uint256, uint256);
}
