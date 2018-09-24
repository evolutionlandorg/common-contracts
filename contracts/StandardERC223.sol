pragma solidity ^0.4.24;

import './interfaces/ERC223ReceivingContract.sol';
import './interfaces/TokenController.sol';
import './interfaces/ApproveAndCallFallBack.sol';
import './interfaces/ERC223.sol';
import './StandardERC20Base.sol';
import './DSAuth.sol';

// This is a contract for demo and test.
contract StandardERC223 is StandardERC20Base, DSAuth, ERC223 {
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 amount);

    bytes32  public  symbol;
    uint256  public  decimals = 18; // standard token precision. override to customize
    // Optional token name
    bytes32   public  name = "";

    address public controller;

    constructor(bytes32 _symbol) public {
        symbol = _symbol;
        controller = msg.sender;
    }

    function setName(bytes32 name_) public auth {
        name = name_;
    }

//////////
// Controller Methods
//////////
    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address _newController) public auth {
        controller = _newController;
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount
    ) public returns (bool success) {
        // Alerts the token controller of the transfer
        if (isContract(controller)) {
            if (!TokenController(controller).onTransfer(_from, _to, _amount))
               revert();
        }

        success = super.transferFrom(_from, _to, _amount);
    }

    /*
     * ERC 223
     * Added support for the ERC 223 "tokenFallback" method in a "transfer" function with a payload.
     */
    function transferFrom(address _from, address _to, uint256 _amount, bytes _data)
        public
        returns (bool success)
    {
        // Alerts the token controller of the transfer
        if (isContract(controller)) {
            if (!TokenController(controller).onTransfer(_from, _to, _amount))
               revert();
        }

        require(super.transferFrom(_from, _to, _amount));

        if (isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _amount, _data);
        }

        emit ERC223Transfer(_from, _to, _amount, _data);

        return true;
    }

    function issue(address _to, uint256 _amount) public auth {
        mint(_to, _amount);
    }

    function destroy(address _from, uint256 _amount) public auth {
        burn(_from, _amount);
    }

    function mint(address _to, uint _amount) public auth {
        _supply = _supply.add(_amount);
        _balances[_to] = _balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    function burn(address _who, uint _value) public auth {
        require(_value <= _balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        _balances[_who] = _balances[_who].sub(_value);
        _supply = _supply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    /*
     * ERC 223
     * Added support for the ERC 223 "tokenFallback" method in a "transfer" function with a payload.
     * https://github.com/ethereum/EIPs/issues/223
     * function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
     */
    /// @notice Send `_value` tokens to `_to` from `msg.sender` and trigger
    /// tokenFallback if sender is a contract.
    /// @dev Function that is called when a user or another contract wants to transfer funds.
    /// @param _to Address of token receiver.
    /// @param _amount Number of tokens to transfer.
    /// @param _data Data to be sent to tokenFallback
    /// @return Returns success of function call.
    function transfer(
        address _to,
        uint256 _amount,
        bytes _data)
        public
        returns (bool success)
    {
        return transferFrom(msg.sender, _to, _amount, _data);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        // Alerts the token controller of the approve function call
        if (isContract(controller)) {
            if (!TokenController(controller).onApprove(msg.sender, _spender, _amount))
                revert();
        }
        
        return super.approve(_spender, _amount);
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData
    ) public returns (bool success) {
        if (!approve(_spender, _amount)) revert();

        ApproveAndCallFallBack(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /// @notice The fallback function: If the contract's controller has not been
    ///  set to 0, then the `proxyPayment` method is called which relays the
    ///  ether and creates tokens as described in the token controller contract
    function ()  public payable {
        if (isContract(controller)) {
            if (! TokenController(controller).proxyPayment.value(msg.value)(msg.sender, msg.sig, msg.data))
                revert();
        } else {
            revert();
        }
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the owner to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public auth {
        if (_token == 0x0) {
            address(msg.sender).transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(address(msg.sender), balance);

        emit ClaimedTokens(_token, address(msg.sender), balance);
    }

////////////////
// Events
////////////////

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}