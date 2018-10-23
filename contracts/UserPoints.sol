pragma solidity ^0.4.24;

import "./DSAuth.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interfaces/IUserPoints.sol";

contract UserPoints is DSAuth, IUserPoints {
    using SafeMath for *;

    // claimedToken event
    event ClaimedTokens(address indexed token, address indexed owner, uint amount);

    bool private singletonLock = false;

    // points
    mapping (address => uint256) public points;

    uint256 public allUserPoints;

    /*
     *  Modifiers
     */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract() public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function pointsSupply() public view returns (uint256) {
        return allUserPoints;
    }

    function pointsBalanceOf(address _user) public view returns (uint256) {
        return points[_user];
    }

    function addPoints(address _user, uint256 _pointAmount) public auth {
        points[_user] = points[_user].add(_pointAmount);
        allUserPoints = allUserPoints.add(_pointAmount);

        emit AddedPoints(_user, points[_user]);
    }

    function subPoints(address _user, uint256 _pointAmount) public auth {
        points[_user] = points[_user].sub(_pointAmount);
        allUserPoints = allUserPoints.sub(_pointAmount);

        allUserPoints = allUserPoints.sub(points[_user]);
        points[_user] = 0;
        emit SubedPoints(_user, _pointAmount);
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