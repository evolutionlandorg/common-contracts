pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "../interfaces/ISettingsRegistry.sol";
import "../DSAuth.sol";
import "../SettingIds.sol";
import "../StringUtil.sol";
import "./interfaces/IEncoder.sol";


contract NFTTemplate is ERC721Token("Evolution Land Objects","EVO"), DSAuth, SettingIds {
    using StringUtil for *;

    IEncoder public encoder;

    // (objectClass => producerId => objectId))
    mapping(uint8 => mapping(uint256 => uint128)) public identifier2ObjectId;
    // (objectClass => (producerId => objectId))
    mapping(uint8 => mapping(uint256 => address)) public allowedIdentifier;


    // https://docs.opensea.io/docs/2-adding-metadata
    string public baseTokenURI;

    /**
     * @dev Atlantis's constructor 
     */

    event SetEncoder(address _oldEncoder, address _newEncoder);
    event NFTOnChain(address _operator, uint256 _tokenId, address _owner, uint256 _mark);
    event CustomNFTOnChain(address _operator, uint256 _tokenId, address _owner, uint256 _mark);

    constructor (IEncoder _encoder) public {
        encoder = _encoder;
    }

    function publishOnChainAuth(uint8 _objectClass, uint256 _producerId, address _user, uint256 _mark) public auth {
        require(allowedIdentifier[_objectClass][_producerId] == msg.sender, "you are not allowed to touch the fields");
        require(identifier2ObjectId[_objectClass][_producerId] < 340282366920938463463374607431768211455, "overflow");
        identifier2ObjectId[_objectClass][_producerId] += 1;
        uint128 objectId =  identifier2ObjectId[_objectClass][_producerId];
        uint256 tokenId = encoder.encodeTokenIdAuth(address(this), _objectClass, _producerId, objectId);

        _mint(_user, tokenId);

        emit CustomNFTOnChain(msg.sender, tokenId, _user, _mark);
    }


    function publishOnChain(address _user, uint256 _mark) public {
        uint8 objectClass = encoder.OBJECT_CLASS();
        uint256 producerId = encoder.CURRENT_LAND();
        require(identifier2ObjectId[objectClass][producerId] < 340282366920938463463374607431768211455, "overflow");

        identifier2ObjectId[objectClass][producerId] += 1;
        uint128 objectId =  identifier2ObjectId[objectClass][producerId];
        uint256 tokenId = encoder.encodeTokenId(address(this), objectId);

        _mint(_user, tokenId);

        emit NFTOnChain(msg.sender, tokenId, _user, _mark);
    }

    function setAllowedIdentifier(uint8 _objectClass, uint256 _producerId, address _operator) onlyOwner {
        allowedIdentifier[_objectClass][_producerId] = _operator;
    }

    function setEncoder(IEncoder _newEncoder) public onlyOwner {
        address oldEncoder = address(encoder);
        encoder = _newEncoder;

        emit SetEncoder(oldEncoder, address(encoder));
    }


    function tokenURI(uint256 _tokenId) public view returns (string) {
        if (super.tokenURI(_tokenId).toSlice().empty()) {
            return baseTokenURI.toSlice().concat(StringUtil.uint2str(_tokenId).toSlice());
        }

        return super.tokenURI(_tokenId);
    }


    function setTokenURI(uint256 _tokenId, string _uri) public auth {
        _setTokenURI(_tokenId, _uri);
    }

    function setBaseTokenURI(string _newBaseTokenURI) public auth  {
        baseTokenURI = _newBaseTokenURI;
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
