const SettingsRegistry = artifacts.require("SettingsRegistry")
module.exports = async (deployer, network) => {

    if(network != "development") {
        return;
    }

    deployer.deploy(SettingsRegistry);
}
