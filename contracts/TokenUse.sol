pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ERC223.sol";
import "./interfaces/ITokenUse.sol";
import "./interfaces/IActivity.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/IInterstellarEncoder.sol";
import "./interfaces/IActivityObject.sol";
import "./SettingIds.sol";
import "./DSAuth.sol";

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
    }

    struct UseOffer {
        address owner;
        uint48 duration;
        // total price of hiring mft for full duration
        uint256 price;
        address acceptedActivity;   // If 0, then accept any activity
    }

    bool private singletonLock = false;

    ISettingsRegistry public registry;
    mapping (uint256 => UseStatus) public tokenId2UseStatus;
    mapping (uint256 => UseOffer) public tokenId2UseOffer;

    mapping (uint256 => address) currentTokenActivities;

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

    // by check this function
    // you can know if an nft is ok to addActivity
    function isObjectReadyToUse(uint256 _tokenId) public view returns (bool) {
        return !isObjectInUseStage(_tokenId) && currentTokenActivities[_tokenId] == address(0);
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

            // already approve that msg.sender == ownerOf(_tokenId)

            _createTokenUseOffer(_tokenId, duration, price, acceptedActivity, _from);
        }
    }


    // need approval from msg.sender
    function createTokenUseOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity) public {
        require(ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId) == msg.sender, "Only can call by the token owner.");

        _createTokenUseOffer(_tokenId, _duration, _price, _acceptedActivity, msg.sender);
    }

    // TODO: be careful with unit of duration and price
    // remember to deal with unit off chain
    function _createTokenUseOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity, address _owner) internal {
        require(tokenId2UseStatus[_tokenId].user == address(0), "Token already in another use.");
        require(tokenId2UseOffer[_tokenId].duration == 0, "Token already in another offer.");
        require(currentTokenActivities[_tokenId] == address(0), "Token already in another activity.");

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(msg.sender, address(this), _tokenId);

        tokenId2UseOffer[_tokenId] = UseOffer({
            owner: _owner,
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
        uint256 expense = uint256(tokenId2UseOffer[_tokenId].price);

        uint256 cut = expense.mul(registry.uintOf(UINT_TOKEN_OFFER_CUT)).div(10000);

        address ring = registry.addressOf(CONTRACT_RING_ERC20_TOKEN);

        ERC20(ring).transferFrom(
            msg.sender, tokenId2UseOffer[_tokenId].owner, expense.sub(cut));

        ERC223(ring).transferFrom(
            msg.sender, registry.addressOf(CONTRACT_REVENUE_POOL), cut, toBytes(msg.sender));

        _takeTokenUseOffer(_tokenId, msg.sender);
    }

    function _takeTokenUseOffer(uint256 _tokenId, address _from) internal {
        require(tokenId2UseOffer[_tokenId].owner != address(0), "Offer does not exist for this token.");
        require(currentTokenActivities[_tokenId] == address(0), "Token already in another activity.");

        tokenId2UseStatus[_tokenId] = UseStatus({
            user: _from,
            owner: tokenId2UseOffer[_tokenId].owner,
            startTime: uint48(now),
            endTime : uint48(now) + tokenId2UseOffer[_tokenId].duration,
            price : tokenId2UseOffer[_tokenId].price,
            acceptedActivity : tokenId2UseOffer[_tokenId].acceptedActivity
            });

        delete tokenId2UseOffer[_tokenId];

    }

    //TODO: allow batch operation
    function tokenFallback(address _from, uint256 _value, bytes _data) public {
        address ring = registry.addressOf(CONTRACT_RING_ERC20_TOKEN);
        if(ring == msg.sender) {
            uint256 tokenId;

            assembly {
                let ptr := mload(0x40)
                calldatacopy(ptr, 0, calldatasize)
                tokenId := mload(add(ptr, 132))
            }

            uint256 expense = uint256(tokenId2UseOffer[tokenId].price);
            require(_value >= expense);

            uint256 cut = expense.mul(registry.uintOf(UINT_TOKEN_OFFER_CUT)).div(10000);

            ERC20(ring).transfer(tokenId2UseOffer[tokenId].owner, expense.sub(cut));

            ERC223(ring).transfer(
                registry.addressOf(CONTRACT_REVENUE_POOL), cut, toBytes(msg.sender));

            _takeTokenUseOffer(tokenId, _from);
        }
    }

    function registerTokenStatus(uint256 _tokenId, address _owner, address _user, uint256 _startTime, uint256 _endTime, uint256 _price, address _acceptedActivity) public auth {
        require(isObjectReadyToUse(_tokenId));

        tokenId2UseStatus[_tokenId] = UseStatus({
            user: _user,
            owner: _owner,
            startTime: uint48(_startTime),
            endTime : uint48(_endTime),
            price : _price,
            acceptedActivity: _acceptedActivity
            });

    }


    // start activity when token has no user at all
    function addActivity(
        uint256 _tokenId, address _user
    ) public auth {
        // require the token user to verify even if it is from business logic.
        // if it is rent by others, can not addActivity by default.
        if(tokenId2UseStatus[_tokenId].user != address(0)) {
            require(_user == tokenId2UseStatus[_tokenId].user);
            require(
                tokenId2UseStatus[_tokenId].acceptedActivity == address(0) || tokenId2UseStatus[_tokenId].acceptedActivity == msg.sender, "Token accepted activity is not accepted.");
        } else {
            require(
                address(0) == _user || ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId) == _user, "you can not use this token.");
        }

        require(tokenId2UseOffer[_tokenId].owner == address(0), "Can not start activity when offering.");

        require(IActivity(msg.sender).supportsInterface(0x6086e7f8), "Msg sender must be activity");

        require(currentTokenActivities[_tokenId] == address(0), "Token should be available.");

        address activityObject = IInterstellarEncoder(registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)).getObjectAddress(_tokenId);
        IActivityObject(activityObject).activityAdded(_tokenId, msg.sender, _user);

        currentTokenActivities[_tokenId] = msg.sender;
    }

    function removeActivity(uint256 _tokenId, address _user) public auth {
                // require the token user to verify even if it is from business logic.
        // if it is rent by others, can not addActivity by default.
        if(tokenId2UseStatus[_tokenId].user != address(0)) {
            require(_user == tokenId2UseStatus[_tokenId].user);
        } else {
            require(
                address(0) == _user || ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).ownerOf(_tokenId) == _user, "you can not use this token.");
        }
        
        require(currentTokenActivities[_tokenId] == msg.sender, "Must stop from current activity");

        address activityObject = IInterstellarEncoder(registry.addressOf(CONTRACT_INTERSTELLAR_ENCODER)).getObjectAddress(_tokenId);
        IActivityObject(activityObject).activityRemoved(_tokenId, msg.sender, _user);

        delete currentTokenActivities[_tokenId];
    }

    function removeTokenUseAndActivity(uint256 _tokenId) public {
        removeTokenUse(_tokenId);

        if (currentTokenActivities[_tokenId] != address(0)) {
            IActivity(currentTokenActivities[_tokenId]).activityStopped(_tokenId);
        }
    }

    function removeTokenUse(uint256 _tokenId) public {
        require(tokenId2UseStatus[_tokenId].user != address(0), "Object does not exist.");

        // when in activity, only user can stop
        if(isObjectInUseStage(_tokenId)) {
            require(tokenId2UseStatus[_tokenId].user == msg.sender);
        }

        _removeTokenUse(_tokenId);
    }

    function _removeTokenUse(uint256 _tokenId) public {
        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(
            address(this), tokenId2UseStatus[_tokenId].owner,  _tokenId);

        delete tokenId2UseStatus[_tokenId];
        delete currentTokenActivities[_tokenId];
    }

    // for user-friendly
    function removeUseAndCreateOffer(uint256 _tokenId, uint256 _duration, uint256 _price, address _acceptedActivity) public {

        removeTokenUse(_tokenId);

        tokenId2UseOffer[_tokenId] = UseOffer({
            owner: msg.sender,
            duration: uint48(_duration),
            price : _price,
            acceptedActivity: _acceptedActivity
            });
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

    function toBytes(address x) public pure returns (bytes b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }
}