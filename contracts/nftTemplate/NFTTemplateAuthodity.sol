pragma solidity ^0.4.23;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
contract NFTTemplateAuthority is Ownable {

    mapping (address => bool) public whiteList;

    event WhiteListModified(address _addr, bool _isProved);

    constructor(address[] _whitelists) public {
        for (uint i = 0; i < _whitelists.length; i ++) {
            whiteList[_whitelists[i]] = true;
        }
    }

    function canCall(
        address _src, address _dst, bytes4 _sig
    ) public view returns (bool) {
        return ( whiteList[_src] && _sig == bytes4(keccak256("publishOnChainAuth(uint8,uint256,address,uint256)")) );
    }

    function modifyWhiteList(address _addr, bool _isProved) public onlyOwner {
        if(whiteList[_addr] != _isProved) {
            whiteList[_addr] = _isProved;
            emit WhiteListModified(_addr, _isProved);
        }
    }
}