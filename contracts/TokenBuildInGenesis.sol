pragma solidity ^0.4.24;

import "./DSAuth.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IBurnableERC20.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./SettingIds.sol";

contract TokenBuildInGenesis is DSAuth, SettingIds {
    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    // burndropTokens event
    event RingBuildInEvent(address indexed token, address indexed owner, uint amount, bytes data);

    event KtonBuildInEvent(address indexed token, address indexed owner, uint amount, bytes data);

    event SetStatus(bool status);

    ISettingsRegistry public registry;

    bool public paused = false;

    bool private singletonLock = false;

    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    modifier isWork() {
        require(!paused, "Not started");
        _;
    }

    function initializeContract(address _registry, bool _status) public singletonLockCall{
        registry = ISettingsRegistry(_registry);
        paused = _status;
        owner = msg.sender;
    }

    /**
    * @dev ERC223 fallback function, make sure to check the msg.sender is from target token contracts
    * @param _from - person who transfer token in for deposits or claim deposit with penalty KTON.
    * @param _amount - amount of token.
    * @param _data - data which indicate the operations.
    */
    function tokenFallback(address _from, uint256 _amount, bytes _data) public isWork{
        bytes32 darwiniaAddress;

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            darwiniaAddress := mload(add(ptr, 132))
        }

        address ring = registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN);
        address kryptonite = registry.addressOf(SettingIds.CONTRACT_KTON_ERC20_TOKEN);

        require((msg.sender == ring) || (msg.sender == kryptonite), "Permission denied");

        require(_data.length == 32, "The address (Darwinia Network) must be in a 32 bytes hexadecimal format");
        require(darwiniaAddress != bytes32(0x0), "Darwinia Network Address can't be empty");

        //  burndrop ring
        if(ring == msg.sender) {
            IBurnableERC20(ring).burn(address(this), _amount);
            emit RingBuildInEvent(msg.sender, _from, _amount, _data);
        }

        //  burndrop kton
        if (kryptonite == msg.sender) {
            IBurnableERC20(kryptonite).burn(address(this), _amount);
            emit KtonBuildInEvent(msg.sender, _from, _amount, _data);
        }
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

    function setPaused(bool _status) public auth {
        paused = _status;
    }

    function togglePaused() public auth {
        paused = !paused;
    }
}
