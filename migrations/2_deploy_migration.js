const LocationCoder = artifacts.require("./LocationCoder.sol");
const TokenLocation = artifacts.require("./TokenLocation.sol");
const InterstellarEncoder = artifacts.require("./InterstellarEncoder.sol");

module.exports = function(deployer, network, accounts) {
    if (network == "develop")
    {
        deployer.then(async () => {
            await deployOnLocal(deployer, network, accounts);
        });
    }
};

async function deployOnLocal(deployer, network, accounts) {
    console.log(network);

    await deployer.deploy(LocationCoder);
    await deployer.link(LocationCoder, TokenLocation);
    await deployer.deploy(TokenLocation);

    await deployer.deploy(InterstellarEncoder);
}
