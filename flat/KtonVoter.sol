// Dependency file: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

// pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


// Dependency file: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

// pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


// Root file: contracts/KtonVoter.sol

pragma solidity ^0.4.24;

// import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/// @title KtonVoter
/// @dev Voting and support specific proposal validator by deposit KTON
/// Vote will be cancel after KTON get withdrawd
/// 1 KTON means one vote
contract KtonVoter {
    address public KTON;

    struct VoterItem {
        // mapping (address => mapping (address => uint256))  public votes;
        mapping (address => uint256) votes;
        // mapping (address => uint256) public                       depositBalances;
        uint256 balance;
        // TODO: address[] candidates;
    }

    struct CandidateItem {
        uint256 voteCount;              // contract address
        uint256 sortedIndex;        // index of the item in the list of sortedCandidate
        bool isRegistered;            // used to tell if the mapping element is defined
        // TODO: address[] voters;
    }

    mapping (address => VoterItem)  public voterItems;
    
    mapping (address => CandidateItem) public cadidateItems;

    // descending
    address[] public sortedCandidates;

    function vote(address _candidate, uint _amount) public {
        require(cadidateItems[_candidate].isRegistered);
        require(ERC20(KTON).transferFrom(msg.sender, address(this), _amount));

        voterItems[msg.sender].votes[_candidate] += _amount;
        voterItems[msg.sender].balance += _amount;

        cadidateItems[_candidate].voteCount += _amount;

        // TODO: update sortedIndex
        quickSort(0, cadidateItems[_candidate].sortedIndex);
    }

    function withdrawFrom(address _candidate, uint _amount) public {
        require(voterItems[msg.sender].votes[_candidate] >= _amount);

        voterItems[msg.sender].votes[_candidate] -= _amount;
        voterItems[msg.sender].balance -= _amount;
        cadidateItems[_candidate].voteCount -= _amount;

        require(ERC20(KTON).transfer(msg.sender, _amount));

        // TODO: update sortedIndex
        quickSort(cadidateItems[_candidate].sortedIndex, sortedCandidates.length - 1);
    }

    function getCandidate(uint _num) public view returns (address candidate){
        require(_num < sortedCandidates.length);
        candidate = sortedCandidates[_num];
    }

    function registerCandidate() public {
        // require(ERC20(KTON).transferFrom(msg.sender, address(this), 1000000000000000000000));
        require(!cadidateItems[msg.sender].isRegistered);

        cadidateItems[msg.sender].isRegistered = true;
        sortedCandidates.push(msg.sender);
        cadidateItems[msg.sender].sortedIndex = sortedCandidates.length - 1;
    }

    // http://www.etherdevops.com/content/sorting-array-integer-ethereum
    function quickSort(uint left, uint right) internal {
        uint i = left;
        uint j = right;
        uint pivot = cadidateItems[sortedCandidates[left + (right - left) / 2]].voteCount;
        while (i <= j) {
            while (cadidateItems[sortedCandidates[i]].voteCount < pivot) i++;
            while (pivot < cadidateItems[sortedCandidates[j]].voteCount) j--;
            if (i <= j) {
                (sortedCandidates[i], sortedCandidates[j]) = (sortedCandidates[j], sortedCandidates[i]);
                cadidateItems[sortedCandidates[i]].sortedIndex = i;
                cadidateItems[sortedCandidates[j]].sortedIndex = j;

                i++;
                j--;
            }
        }
        if (left < j)
            quickSort(left, j);
        if (i < right)
            quickSort(i, right);
    }
}