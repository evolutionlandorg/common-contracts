pragma solidity ^0.4.23;

contract IReward {
    function checkRewardAvailable(address _token) external view returns(bool);
    function rewardAmount(uint256 _amount) external; 
}
