pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "../interfaces/ISettingsRegistry.sol";
import "../DSAuth.sol";
import "../SettingIds.sol";
import "../StringUtil.sol";
import "../interfaces/IInterstellarEncoderV3.sol";


contract NFTTemplate is ERC721Token, DSAuth, SettingIds {
    using StringUtil for *;

    IInterstellarEncoderV3 encoder;

    // https://docs.opensea.io/docs/2-adding-metadata
    string public baseTokenURI;

    /**
     * @dev Atlantis's constructor 
     */

    event SetEncoder(address _oldEncoder, address _newEncoder);

    constructor (string _name, string _symbol, IInterstellarEncoderV3 _encoder) ERC721Token(_name, _symbol) public {
        encoder = _encoder;
    }


    function tokenURI(uint256 _tokenId) public view returns (string) {
        if (super.tokenURI(_tokenId).toSlice().empty()) {
            return baseTokenURI.toSlice().concat(StringUtil.uint2str(_tokenId).toSlice());
        }

        return super.tokenURI(_tokenId);
    }

    function setEncoder(IInterstellarEncoderV3 _newEncoder) public auth {
        address oldEncoder = address(encoder);
        encoder = _newEncoder;

        emit SetEncoder(oldEncoder, address(encoder));
    }

    function setTokenURI(uint256 _tokenId, string _uri) public auth {
        _setTokenURI(_tokenId, _uri);
    }

    function setBaseTokenURI(string _newBaseTokenURI) public auth  {
        baseTokenURI = _newBaseTokenURI;
    }

    function mintObject(address _to, uint128 _objectId) public auth returns (uint256 _tokenId) {

        _tokenId = encoder.encodeTokenIdForObjectContract(
            address(this), msg.sender, _objectId);
        super._mint(_to, _tokenId);
    }

    function burnObject(address _to, uint128 _objectId) public auth returns (uint256 _tokenId) {

        _tokenId = encoder.encodeTokenIdForObjectContract(
            address(this), msg.sender, _objectId);
        super._burn(_to, _tokenId);
    }

    function mint(address _to, uint256 _tokenId) public auth {
        super._mint(_to, _tokenId);
    }

    function burn(address _to, uint256 _tokenId) public auth {
        super._burn(_to, _tokenId);
    }

    //@dev user invoke approveAndCall to create auction
    //@param _to - address of auction contractß
    function approveAndCall(
        address _to,
        uint _tokenId,
        bytes _extraData
    ) public {
        // set _to to the auction contract
        approve(_to, _tokenId);

        if(!_to.call(
                bytes4(keccak256("receiveApproval(address,uint256,bytes)")), abi.encode(msg.sender, _tokenId, _extraData)
                )) {
            revert();
        }
    }
}
