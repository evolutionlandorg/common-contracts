const TokenLocation = artifacts.require("./TokenLocation.sol");

module.exports = function(deployer, network, accounts) {
    if (network == "develop")
    {
        deployOnLocal(deployer, network, accounts);
    }
};

function deployOnLocal(deployer, network, accounts) {
    console.log(network);

    deployer.deploy([
        TokenLocation
    ]);
}
