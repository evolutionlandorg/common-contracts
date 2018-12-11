const TokenUse = artifacts.require('TokenUse');
const TokenUseAuthority = artifacts.require('TokenUseAuthority');
const SettingsRegistry = artifacts.require('SettingsRegistry');
const Proxy = artifacts.require('OwnedUpgradeabilityProxy');


const conf = {
    registry_address: '0xd8b7a3f6076872c2c37fb4d5cbfeb5bf45826ed7',
    apostleBaseProxy_address: '0x23236af7d03c4b0720f709593f5ace0ea92e77cf',
}

module.exports = async(deployer, network) => {
    if(network == 'kovan') {
        return;
    }

    deployer.deploy(Proxy);
    deployer.deploy(TokenUse)
        .then(async() => {
        await deployer.deploy(TokenUseAuthority, [conf.apostleBaseProxy_address]);
    }).then(async() => {
        let registry = await SettingsRegistry.at(conf.registry_address);

        let tokenUseId = await TokenUse.at(TokenUse.address).CONTRACT_TOKEN_USE.call();
        await registry.setAddressProperty(tokenUseId, Proxy.address);
        console.log("REGISTER DONE!");

        await Proxy.at(Proxy.address).upgradeTo(TokenUse.address);
        console.log("UPGRADE DONE!");

        let tokenUseProxy = await TokenUse.at(Proxy.address);
        await tokenUseProxy.initializeContract(conf.registry_address);
        console.log("INITIALIZE DONE!");

        // set authority
        await tokenUseProxy.setAuthority(TokenUseAuthority.address);


    })


}