pragma solidity ^0.4.23;

import "../RBACWithAuth.sol";
import "./interfaces/INFTTemplate.sol";

contract NFTController is RBACWithAuth {


    constructor(address _operator) {
        adminAddRole(_operator, ROLE_AUTH_CONTROLLER);
    }

    function publishNftOnChain(address _nftTemplate, uint8 _objectClass, uint256 _producerId, address _user, uint256 _mark) public onlyAuthController {
        INFTTemplate(_nftTemplate).publishOnChainAuth(_objectClass, _producerId, _user, _mark);
    }

}
