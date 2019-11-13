pragma solidity ^0.4.24;

import "./DSAuth.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./interfaces/ERC223.sol";
import "./SettingIds.sol";

contract TokenBurnDrop is DSAuth, SettingIds {
    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    // burndropTokens event
    event BurndropTokens(address indexed token, address indexed owner, uint amount, bytes data);

    ISettingsRegistry public registry;

    function initializeContract(address _registry) public onlyOwner{
        registry = ISettingsRegistry(_registry);
    }

    /**
    * @dev ERC223 fallback function, make sure to check the msg.sender is from target token contracts
    * @param _from - person who transfer token in for deposits or claim deposit with penalty KTON.
    * @param _amount - amount of token.
    * @param _data - data which indicate the operations.
    */
    function tokenFallback(address _from, uint256 _amount, bytes _data) public {
        address ring = registry.addressOf(SettingIds.CONTRACT_RING_ERC20_TOKEN);
        address kryptonite = registry.addressOf(SettingIds.CONTRACT_KTON_ERC20_TOKEN);

        require((msg.sender == ring) || (msg.sender == kryptonite), "Permission denied");

        require(_data.length == 32, "The address (Darwinia Network) must be in a 64-bit hexadecimal format");

        //  burndrop ring
        if(ring == msg.sender) {
            ERC223(ring).transfer(address(0), _amount);
        }

        //  burndrop kton
        if (kryptonite == msg.sender) {
            ERC223(kryptonite).transfer(address(0), _amount);
        }

        emit BurndropTokens(msg.sender, _from, _amount, _data);
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
