pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ITokenUse.sol";
import "./interfaces/IActivity.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./SettingIds.sol";
import "./DSAuth.sol";

contract TokenUse is DSAuth, ITokenUse, SettingIds {
    using SafeMath for *;

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    struct UseStatus {
        uint256 tokenId;
        address user;
        uint48  startTime;
        uint48  endTime;
        uint256 price;  // RING per second.
        address acceptedActivity;   // can only be used in this activity.
    }

    struct UseOffer {
        uint256 tokenId;
        uint48 duration;
        uint256 price;
        address acceptedActivity;   // If 0, then accept any activity
    }

    bool private singletonLock = false;

    ISettingsRegistry public registry;

    mapping (uint256 => address) currentTokenActivities;

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
        require(ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId) == msg.sender, "Only can call by the token owner.");

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(msg.sender, address(this), _tokenId);

        _createTokenUseOffer(_tokenId, _duration, _price, _acceptedActivity, msg.sender);
    }

    function _createTokenUseOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity, address _owner) internal {
        require(tokenId2UseStatus[_tokenId].tokenId == 0, "Token already in another use.");
        require(tokenId2UseOffer[_tokenId].tokenId == 0, "Token already in another offer.");
        require(currentTokenActivities[_tokenId] == address(0), "Token already in another activity.");

        tokenId2UseOffer[_tokenId] = UseOffer({
            tokenId: _tokenId,
            duration: uint48(_duration),
            price : _price,
            acceptedActivity: _acceptedActivity
        });
    }

    function cancelTokenUseOffer(uint256 _tokenId) public {
        require(ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId) == msg.sender, "Only token owner can cancel the offer.");

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(address(this), msg.sender,  _tokenId);

        delete tokenId2UseOffer[_tokenId];
    }

    function takeTokenUseOffer(uint256 _tokenId) public {
        // calculate the required expense to hire this token.
        require(tokenId2UseOffer[_tokenId].tokenId != 0, "Offer does not exist for this token.");
        require(currentTokenActivities[_tokenId] == address(0), "Token already in another activity.");

        uint256 expense = uint256(tokenId2UseOffer[_tokenId].duration).mul(tokenId2UseOffer[_tokenId].price);

        ERC20(registry.addressOf(CONTRACT_RING_ERC20_TOKEN)).transferFrom(
            msg.sender, ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId), expense);

        tokenId2UseStatus[_tokenId] = UseStatus({
            tokenId: _tokenId,
            user: msg.sender,
            startTime: uint48(now),
            endTime : uint48(now) + tokenId2UseOffer[_tokenId].duration,
            price : tokenId2UseOffer[_tokenId].price,
            acceptedActivity : tokenId2UseOffer[_tokenId].acceptedActivity
        });

        delete tokenId2UseOffer[_tokenId];
    }

    // start activity when token has no user at all
    function startActivity(
        uint256 _tokenId, address _user
    ) public auth {
        require(IActivity(msg.sender).isActivity(), "Msg sender must be activity");

        require(tokenId2UseOffer[_tokenId].tokenId == 0, "Can not start activity when offering.");

        if(tokenId2UseStatus[_tokenId].tokenId != 0) {
            require(_user == tokenId2UseStatus[_tokenId].user, "User is not correct.");
            require(currentTokenActivities[_tokenId] == address(0), "Token should be available.");
            require(
                tokenId2UseStatus[_tokenId].acceptedActivity == address(0) || 
                tokenId2UseStatus[_tokenId].acceptedActivity == msg.sender, "Token accepted activity is not accepted.");
            currentTokenActivities[_tokenId] = msg.sender;
        } else {
            require(_user == ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId), "User is required to be owner.");
            
            currentTokenActivities[_tokenId] = msg.sender;
        }
    }

    function stopActivity(uint256 _tokenId, address _user) public auth {
        require(currentTokenActivities[_tokenId] == msg.sender, "Must stop from current activity");

        if(tokenId2UseStatus[_tokenId].tokenId != 0) {
            if (_user == tokenId2UseStatus[_tokenId].user) {
                delete currentTokenActivities[_tokenId];
            } else {
                require(_user == ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId), "User is required to be owner.");
                require(!isObjectInUseStage(_tokenId));

                _removeTokenUse(_tokenId);
                delete currentTokenActivities[_tokenId];
            }
        } else {
            require(_user == ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId), "User is required to be owner.");
            
            delete currentTokenActivities[_tokenId];
        }


        // only user can stop mining directly.
        require(tokenId2UseStatus[_tokenId].user == _user, "Only token owner can stop the activity.");

        if (_user == ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId)) {
            delete tokenId2UseStatus[_tokenId];
        } else {
            currentTokenActivities[_tokenId] = address(0);
        }
    }

    function removeTokenUse(uint256 _tokenId) public {
        require(tokenId2UseStatus[_tokenId].tokenId != 0, "Object does not exist.");

        // when in activity, only user can stop
        if(isObjectInUseStage(_tokenId)) {
            require(tokenId2UseStatus[_tokenId].user == msg.sender);
        }

        _removeTokenUse(_tokenId);
    }

    function _removeTokenUse(uint256 _tokenId) public {
        IActivity(tokenId2UseStatus[_tokenId].acceptedActivity).tokenUseStopped(_tokenId);

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(
            address(this), ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId),  _tokenId);

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