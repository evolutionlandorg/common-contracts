pragma solidity ^0.4.24;

contract ERC721AdaptorAuthority {
    mapping (address => bool) public whiteList;

    constructor(address[] _whitelists) public {
        for (uint i = 0; i < _whitelists.length; i ++) {
            whiteList[_whitelists[i]] = true;
        }
    }

    function canCall(
        address _src, address _dst, bytes4 _sig
    ) public view returns (bool) {
        return  ( whiteList[_src] && _sig == bytes4(keccak256("convertTokenId(uint256)")) ) ||
                ( whiteList[_src] && _sig == bytes4(keccak256("approveOriginToken(address,uint256)")) );
    }
}