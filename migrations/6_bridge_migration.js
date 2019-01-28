const ERC721Bridge = artifacts.require("ERC721Bridge");
const Proxy = artifacts.require("OwnedUpgradeabilityProxy");
const SettingsRegistry = artifacts.require("SettingsRegistry");
const ObjectOwnershipAuthorityV2 = artifacts.require("ObjectOwnershipAuthorityV2");
const ObjectOwnershipV2 = artifacts.require("ObjectOwnershipV2");
// TODO
const InterstellarEncoderV3 = artifacts.require("InterstellarEncoderV3");

const conf = {
    registry_address: "0xd8b7a3f6076872c2c37fb4d5cbfeb5bf45826ed7",
    objectOwnershipProxy_address: "0xe94b9ebf9609a0d20270e8de317381ff4bcdcd79",
    apostleBaseProxy_address: "0x23236af7d03c4b0720f709593f5ace0ea92e77cf",
    landBaseProxy_address: "0x72eec3a6a9a8628e0f7a2dbbad5df083bd985c5f"
}

var erc721BridgeProxy_address;

module.exports = async (deployer, network) => {

    if(network == "kovan") {
        return;
    }

    deployer.deploy(Proxy).then(async() => {
        let erc721BridgeProxy = await Proxy.deployed();
        erc721BridgeProxy_address = erc721BridgeProxy.address;
        console.log("ERC721BridgeProxy: ", erc721BridgeProxy_address);
        await deployer.deploy(ERC721Bridge);
        await deployer.deploy(ObjectOwnershipAuthorityV2, [erc721BridgeProxy_address, conf.apostleBaseProxy_address, conf.landBaseProxy_address]);
        await deployer.deploy(InterstellarEncoderV3);
    }).then(async() => {

        // register address in registry
        let brige = await ERC721Bridge.deployed();
        let bridgeId = await brige.CONTRACT_ERC721_BRIDGE.call();
        let registry = await SettingsRegistry.at(conf.registry_address);
        await registry.setAddressProperty(bridgeId, erc721BridgeProxy_address);

        // upgrade
        let proxy = await Proxy.at(erc721BridgeProxy_address);
        await proxy.upgradeTo(ERC721Bridge.address);

        // initialize
        let erc721Bridge = await ERC721Bridge.at(erc721BridgeProxy_address);
        await erc721Bridge.initializeContract(conf.registry_address);

        // setAuthority
        let objectOwnershipProxy = await ObjectOwnershipV2.at(conf.objectOwnershipProxy_address);
        await objectOwnershipProxy.setAuthority(ObjectOwnershipAuthorityV2.address);


    })
}