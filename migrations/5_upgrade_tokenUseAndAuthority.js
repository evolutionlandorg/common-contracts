const Proxy = artifacts.require('OwnedUpgradeabilityProxy');
const TokenUse = artifacts.require('TokenUse');
const TokenUseAuthority = artifacts.require('TokenUseAuthority');

const conf = {
    tokenUseProxy_address: '0xd2bcd143db59ddd43df2002fbf650e46b2b7ea19',
    apostleBaseProxy_address: '0x23236af7d03c4b0720f709593f5ace0ea92e77cf',
    landResourceProxy_address: '0x6bcb3c94040ba63e4da086f2a8d0d6f5f72b8490'
}

module.exports = async(deployer, network) => {

    if(network != 'kovan') {
        return;
    }

    deployer.deploy(TokenUseAuthority, [conf.apostleBaseProxy_address, conf.landResourceProxy_address]);
    deployer.deploy(TokenUse).then(async() => {
        await Proxy.at(conf.tokenUseProxy_address).upgradeTo(TokenUse.address);

        let tokenUseProxy = await TokenUse.at(conf.tokenUseProxy_address);
        await tokenUseProxy.setAuthority(TokenUseAuthority.address);
    })


}