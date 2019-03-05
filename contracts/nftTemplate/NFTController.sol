pragma solidity ^0.4.23;

import "../DSAuth.sol";
import "../interfaces/IInterstellarEncoderV3.sol";
import "../interfaces/IMintableERC20.sol";

contract NFTController is DSAuth {

    IInterstellarEncoderV3 encoder;

    mapping (address => uint128) nftTemplate2ObjectId;

    constructor(IInterstellarEncoderV3 _encoder) {
        encoder = _encoder;
    }

    event NFTOnChain(address _operator, address _nftTemplate, uint256 _tokenId, address _owner, uint256 _mark);


    function mintObject(address _nftTemplate, uint8 _objectClass, uint256 _producerId, address _user, uint256 _mark) public auth {
        uint128 objectId = nftTemplate2ObjectId[_nftTemplate] += 1;
        require(objectId <= 340282366920938463463374607431768211455, "overflow");

        uint256 tokenId = encoder.encodeTokenId(_nftTemplate, _objectClass, objectId);

        IMintableERC20 nftTemplate = IMintableERC20(_nftTemplate);

        nftTemplate.mint(_user, tokenId);

        emit NFTOnChain(msg.sender, _nftTemplate, tokenId, _user, _mark);
    }

}
