const Proxy = artifacts.require('OwnedUpgradeabilityProxy');
const ERC721Bridge = artifacts.require("ERC721Bridge");

const conf = {
    erc721Bridge_proxy: '0x3af088062a6ab3b9706eb1c58506fc0fcf898588'
}

module.exports = async(deployer, network) => {

    if(network != 'kovan') {
        return;
    }

    deployer.deploy(ERC721Bridge).then(async() => {
        await Proxy.at(conf.erc721Bridge_proxy).upgradeTo(ERC721Bridge.address);
    })


}