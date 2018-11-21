pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ITokenActivity.sol";
import "./interfaces/IActivity.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./SettingIds.sol";
import "./DSAuth.sol";

contract TokenActivity is DSAuth, ITokenActivity, SettingIds {

    struct ActivityStatus {
        address user;
        address owner;
        uint48  startTime;
        uint48  endTime;
        uint256 price;  // RING per second.
        address activityContract;   // can only be used in this activity.
        bool isInUse;
    }

    bool private singletonLock = false;

    ISettingsRegistry public registry;

    mapping (uint256 => ActivityStatus) public tokenId2ActivityStatus;

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

    function isObjectInActivity(uint256 _tokenId) public view returns (bool) {
        if (tokenId2ActivityStatus[_tokenId].user == address(0)) {
            return false;
        }
        
        return tokenId2ActivityStatus[_tokenId].startTime <= now && now <= tokenId2ActivityStatus[_tokenId].endTime;
    }

    function getTokenOwner(uint256 _tokenId) public view returns (address) {
        return tokenId2ActivityStatus[_tokenId].owner;
    }

    function getTokenUser(uint256 _tokenId) public view returns (address) {
        return tokenId2ActivityStatus[_tokenId].user;
    }

    function startTokenActivityFromContract(
        uint256 _tokenId, address _user, address _owner, uint256 _startTime, uint256 _endTime, uint256 _price
    ) public auth {
        require(tokenId2ActivityStatus[_tokenId].user == address(0), "Token already in another activity.");
        require(_user != address(0), "User can not be zero.");
        require(_owner != address(0), "Owner can not be zero.");
        require(IActivity(msg.sender).isActivity(), "Msg sender must be activity");

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(_owner, address(this), _tokenId);

        tokenId2ActivityStatus[_tokenId] = ActivityStatus({
            user: _user,
            owner: _owner,
            startTime: uint48(_startTime),
            endTime : uint48(_endTime),
            price : _price,
            activityContract : msg.sender,
            isInUse: true
        });
    }

    // TODO: startTokenActivity for those are not in use yet. One Object can not be used twice. TODO: check the time.

    function stopTokenActivityFromContract(uint256 _tokenId) public auth {
        require(
            tokenId2ActivityStatus[_tokenId].activityContract == msg.sender || tokenId2ActivityStatus[_tokenId].activityContract == address(0), "Msg sender must be the activity");
        require(tokenId2ActivityStatus[_tokenId].isInUse == true, "Token already in another activity.");

        tokenId2ActivityStatus[_tokenId].isInUse = false;
    }

    function removeTokenActivity(uint256 _tokenId) public {
        require(tokenId2ActivityStatus[_tokenId].user != address(0), "Object does not exist.");

        // require(tokenId2ActivityStatus[_tokenId].user == msg.sender || tokenId2ActivityStatus[_tokenId].owner == msg.sender), "Only user or owner can stop.";

        // when in activity, only user can stop
        if(isObjectInActivity(_tokenId)) {
            // TODO: Or require penalty
            require(tokenId2ActivityStatus[_tokenId].user == msg.sender);
        }

        ERC721(registry.addressOf(CONTRACT_OBJECT_OWNERSHIP)).transferFrom(address(this), tokenId2ActivityStatus[_tokenId].owner, _tokenId);

        IActivity(tokenId2ActivityStatus[_tokenId].activityContract).activityStopped(_tokenId);

        delete tokenId2ActivityStatus[_tokenId];
    }
}