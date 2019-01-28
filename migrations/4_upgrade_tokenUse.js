const Proxy = artifacts.require('OwnedUpgradeabilityProxy');
const TokenUse = artifacts.require('TokenUse');

const conf = {
    tokenUseProxy_address: '0xd2bcd143db59ddd43df2002fbf650e46b2b7ea19'
}

module.exports = async(deployer, network) => {

    if(network == 'kovan') {
        return;
    }

    deployer.deploy(TokenUse).then(async() => {
        await Proxy.at(conf.tokenUseProxy_address).upgradeTo(TokenUse.address);
    })


}