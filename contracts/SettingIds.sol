pragma solidity ^0.4.24;

/**
    Id definitions for SettingsRegistry.sol
    Can be used in conjunction with the settings registry to get properties
*/
contract SettingIds {
    bytes32 public constant CONTRACT_RING_ERC20_TOKEN = "RINGERC20Token";

    bytes32 public constant CONTRACT_ATLANTIS_ERC721LAND = "AtlantisERC721";

    bytes32 public constant CONTRACT_CLOCK_AUCTION = "ClockAuction";

    bytes32 public constant CONTRACT_LAND_DATA = "LandData";

    // Cut owner takes on each auction, measured in basis points (1/100 of a percent).
    // Values 0-10,000 map to 0%-100%
    // set ownerCut to 4%
    // ownerCut = 400;
    bytes32 public constant UINT_AUCTION_CUT = "UINT_AUCTION_CUT";  // Denominator is 10000


    // default is 20 RING
    // RING: 20000000000000000000
    bytes32 public constant CONTRACT_AUCTION_CLAIM_BOUNTY = "CONTRACT_AUCTION_CLAIM_BOUNTY";  // Denominator is 10000

    // BidWaitingTime in seconds, default is 30 minutes
    // necessary period of time from invoking bid action to successfully taking the land asset.
    // if someone else bid the same auction with higher price and within bidWaitingTime, your bid failed.
    bytes32 public constant UINT_AUCTION_BID_WAITING_TIME = "UINT_AUCTION_BID_WAITING_TIME";
}