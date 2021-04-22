// Dependency file: contracts/interfaces/IAuthority.sol

// pragma solidity ^0.4.24;

contract IAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

// Dependency file: contracts/DSAuth.sol

// pragma solidity ^0.4.24;

// import 'contracts/interfaces/IAuthority.sol';

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

/**
 * @title DSAuth
 * @dev The DSAuth contract is reference implement of https://github.com/dapphub/ds-auth
 * But in the isAuthorized method, the src from address(this) is remove for safty concern.
 */
contract DSAuth is DSAuthEvents {
    IAuthority   public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(IAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == owner) {
            return true;
        } else if (authority == IAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}


// Root file: contracts/MintAndBurnMutableAuthority.sol

pragma solidity ^0.4.24;

// import "contracts/DSAuth.sol";

contract MintAndBurnAuthority is DSAuth {

    mapping (address => bool) public allowList;

    constructor(address[] _allowlists) public {
        for (uint i = 0; i < _allowlists.length; i ++) {
            allowList[_allowlists[i]] = true;
        }
    }

    function canCall(
        address _src, address _dst, bytes4 _sig
    ) public view returns (bool) {
        return ( allowList[_src] && _sig == bytes4(keccak256("mint(address,uint256)")) ) ||
        ( allowList[_src] && _sig == bytes4(keccak256("burn(address,uint256)")) );
    }

    function addAllowAddress(address allowAddress) public onlyOwner{
        allowList[allowAddress] = true;
    }

    function removeAllowAddress(address allowAddress) public onlyOwner{
        allowList[allowAddress] = false;
    }
}