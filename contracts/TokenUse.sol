pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ITokenUse.sol";
import "./interfaces/IActivity.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./SettingIds.sol";
import "./DSAuth.sol";
import "./interfaces/IApostleBase.sol";

contract TokenUse is DSAuth, ITokenUse, SettingIds {
    using SafeMath for *;

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    struct UseStatus {
        address user;
        address owner;
        uint48  startTime;
        uint48  endTime;
        uint256 price;  // RING per second.
        address acceptedActivity;   // can only be used in this activity.
        address workingActivity;    // 0 means no working activity currently
    }

    struct UseOffer {
        address owner;
        uint48 duration;
        uint256 price;
        address acceptedActivity;   // If 0, then accept any activity
    }

    bool private singletonLock = false;

    ISettingsRegistry public registry;

    mapping (uint256 => UseStatus) public tokenId2UseStatus;

    mapping (uint256 => UseOffer) public tokenId2UseOffer;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract(address _registry) public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        registry = ISettingsRegistry(_registry);
    }

    // false if it is not in useStage
    function isObjectInUseStage(uint256 _tokenId) public view returns (bool) {
        if (tokenId2UseStatus[_tokenId].user == address(0)) {
            return false;
        }
        
        return tokenId2UseStatus[_tokenId].startTime <= now && now <= tokenId2UseStatus[_tokenId].endTime;
    }


    function getTokenOwner(uint256 _tokenId) public view returns (address) {
        return tokenId2UseStatus[_tokenId].owner;
    }

    function getTokenUser(uint256 _tokenId) public view returns (address) {
        return tokenId2UseStatus[_tokenId].user;
    }

    function receiveApproval(address _from, uint _tokenId, bytes _data) public {
        if(msg.sender == registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)) {
            uint256 duration;
            uint256 price;
            address acceptedActivity;
            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize)
                duration := mload(add(ptr, 132))
                price := mload(add(ptr, 164))
                acceptedActivity := mload(add(ptr, 196))
            }

            // already approve that msg.sebder == ownerOf(_tokenId)

            _createTokenUseOffer(_tokenId, duration, price, acceptedActivity, _from);
        }
    }


    function createTokenUseOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity) public {

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(msg.sender, address(this), _tokenId);
        // already approve that msg.sender == ownerOf(_tokenId)
        _createTokenUseOffer(_tokenId, _duration, _price, _acceptedActivity, msg.sender);
    }

    // TODO: be careful with unit of duration and price
    // remember to deal with unit off chain
    function _createTokenUseOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity, address _owner) internal {
        require(tokenId2UseStatus[_tokenId].user == address(0), "Token already in another use.");
        require(IApostleBase(registry.addressOf(CONTRACT_MINER)).isReadyToBreed(_tokenId), "it is having baby. wait.");

        tokenId2UseOffer[_tokenId] = UseOffer({
            owner: msg.sender,
            duration: uint48(_duration),
            price : _price,
            acceptedActivity: _acceptedActivity
            });
    }

    function cancelTokenUseOffer(uint256 _tokenId) public {
        require(tokenId2UseOffer[_tokenId].owner == msg.sender, "Only token owner can cancel the offer.");

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(address(this), msg.sender, _tokenId);

        delete tokenId2UseOffer[_tokenId];
    }

    function takeTokenUseOffer(uint256 _tokenId) public {
        // calculate the required expense to hire this token.
        require(tokenId2UseOffer[_tokenId].owner != address(0), "Offer does not exist for this token.");

        uint256 expense = uint256(tokenId2UseOffer[_tokenId].duration).mul(tokenId2UseOffer[_tokenId].price);

        ERC20(registry.addressOf(CONTRACT_RING_ERC20_TOKEN)).transferFrom(msg.sender, tokenId2UseOffer[_tokenId].owner, expense);

        tokenId2UseStatus[_tokenId] = UseStatus({
            user: msg.sender,
            owner: tokenId2UseOffer[_tokenId].owner,
            startTime: uint48(now),
            endTime : uint48(now) + tokenId2UseOffer[_tokenId].duration,
            price : tokenId2UseOffer[_tokenId].price,
            acceptedActivity : tokenId2UseOffer[_tokenId].acceptedActivity,
            workingActivity: address(0)
        });

        delete tokenId2UseOffer[_tokenId];
    }

    // allow batch operation for user-friendly concern
    // recommand # of apostle <= 5 per operation
    function tokenFallback(address _from, uint256 _value, bytes _data) public {
        assembly {

        }
    }

    // start activity when token has no user at all
    function startTokenUseFromActivity(
        uint256 _tokenId, address _user, address _owner, uint256 _startTime, uint256 _endTime, uint256 _price
    ) public auth {
        require(tokenId2UseStatus[_tokenId].user == address(0), "Token already in another use.");
        require(_user != address(0), "User can not be zero.");
        require(_owner != address(0), "Owner can not be zero.");
        require(IActivity(msg.sender).isActivity(), "Msg sender must be activity");

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(_owner, address(this), _tokenId);

        tokenId2UseStatus[_tokenId] = UseStatus({
            user: _user,
            owner: _owner,
            startTime: uint48(_startTime),
            endTime : uint48(_endTime),
            price : _price,
            acceptedActivity : msg.sender,
            workingActivity: msg.sender
        });
    }

    // for all erc721 tokens, both owned by msg.sender, or hired.
    // @param _owner - in real-life use case, _owner == _user or _owner == this
    //                  so there is no need to use address[] _owners for now
    function batchStartTokenUseFromActivity(
        uint256[] _tokenIds, address _user, address _owner, uint256 _startTime, uint256 _endTime, uint256 _price
    ) public auth {
        require(_user != address(0), "User can not be zero.");
        require(_owner != address(0), "Owner can not be zero.");
        require(IActivity(msg.sender).isActivity(), "Msg sender must be activity");

        ERC721 nft = ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP));

        uint length = _tokenIds.length;
        for(uint i = 0; i < length; i++) {
            require(tokenId2UseStatus[_tokenIds[i]].user == address(0), "Token already in another use.");

            nft.transferFrom(_owner, address(this), _tokenIds[i]);

            tokenId2UseStatus[_tokenIds[i]] = UseStatus({
                user: _user,
                owner: _owner,
                startTime: uint48(_startTime),
                endTime : uint48(_endTime),
                price : _price,
                acceptedActivity : msg.sender,
                workingActivity: msg.sender
            });
        }
    }

    // TODO: startTokenActivity for those are not in use yet. One Object can not be used twice. TODO: check the time.
    function stopTokenUseFromActivity(uint256 _tokenId) public auth {
        require(
            tokenId2UseStatus[_tokenId].acceptedActivity == msg.sender || tokenId2UseStatus[_tokenId].acceptedActivity == address(0), "Msg sender must be the activity");
        require(tokenId2UseStatus[_tokenId].workingActivity == msg.sender, "Token already in another activity.");

        tokenId2UseStatus[_tokenId].workingActivity = address(0);
    }

    function removeTokenUse(uint256 _tokenId) public {
        require(tokenId2UseStatus[_tokenId].user != address(0), "Object does not exist.");

//         require(tokenId2UseStatus[_tokenId].user == msg.sender || tokenId2UseStatus[_tokenId].owner == msg.sender, "Only user or owner can stop.");

        // when in activity, only user can stop
        if(isObjectInUseStage(_tokenId)) {
            // TODO: Or require penalty
            // anyone can send transaction to trigger this function
            // only if its employment is expired
            require(tokenId2UseStatus[_tokenId].endTime > 0 && now >= tokenId2UseStatus[_tokenId].endTime);
        }

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(address(this), tokenId2UseStatus[_tokenId].owner, _tokenId);

        IActivity(tokenId2UseStatus[_tokenId].acceptedActivity).tokenUseStopped(_tokenId);

        delete tokenId2UseStatus[_tokenId];
    }

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public auth {
        if (_token == 0x0) {
            owner.transfer(address(this).balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);

        emit ClaimedTokens(_token, owner, balance);
    }
}