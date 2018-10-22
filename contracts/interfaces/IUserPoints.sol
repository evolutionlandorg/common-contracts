pragma solidity ^0.4.24;

contract IUserPoints {
    event AddedPoints(address indexed user, uint256 pointAmount);
    event SubedPoints(address indexed user, uint256 pointAmount);

    function addTickets(address _user, uint256 _pointAmount) public;

    function subPoints(address _user, uint256 _pointAmount) public;
}
