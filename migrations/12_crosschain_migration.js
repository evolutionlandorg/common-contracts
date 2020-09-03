const CrossChain = artifacts.require("CrossChain")
const Proxy = artifacts.require('OwnedUpgradeabilityProxy')
const CrossChainFees = artifacts.require("CrossChainFees")
const ERC223 = artifacts.require("StandardERC223")
const ISettingsRegistry = artifacts.require("ISettingsRegistry")

module.exports = async (deployer, network, accounts) => {
    console.log('CrossChain Test, deployer:', accounts, accounts[0])
    if (network != "ropsten") {
        return
    }

    const params = {
        ropsten: {
            registry: "0x6982702995b053A21389219c1BFc0b188eB5a372",
            isPaused: false,
            crossChainProxy: '0xff1338B614eD70FA15896673274e97679b32c11e',
            crossChainFeesProxy: '0x67d2dEEB128C0C359919ed12E9cc2352DF531dfa',
            ring: '0xb52FBE2B925ab79a821b261C82c5Ba0814AAA5e0',
            kton: '0x1994100c58753793D52c6f457f189aa3ce9cEe94',
            settingsRegistry: '0x6982702995b053A21389219c1BFc0b188eB5a372'
        }
    }

    let crossChainImpl = await CrossChain.new()
    console.log('crossChain.address: ', crossChainImpl.address)

    let crossChainProxy = await Proxy.at(params[network].crossChainProxy)
    console.log('crossChainProxy deployed')

    await crossChainProxy.upgradeTo(crossChain.address)
    console.log('crossChain upgradeTo crossChainProxy')

    let crossChainFeesImpl = await CrossChainFees.new();
    console.log('crossChainFees.address: ', crossChainFeesImpl.address)

    let crossChainFeesProxy = await Proxy.at(params[network].crossChainFeesProxy)
    console.log('crossChainFeesProxy deployed')

    await crossChainFeesProxy.upgradeTo(crossChainFeesImpl.address)
    console.log('crossChainFees upgradeTo crossChainFeesProxy')

    await crossChainFeesProxy.initializeContract(params[network].settingsRegistry, web3.utils.toWei('1'), false)

    let crossChain = await CrossChain.at(params[network].crossChainProxy)
    await crossChain.initializeContract(params[network].settingsRegistry, false)
    await crossChain.addSupportToken(params[network].ring);
    await crossChain.addSupportToken(params[network].kton);

    let registry = await ISettingsRegistry.at(params[network].settingsRegistry)
    await registry.setAddressProperty('0x434f4e54524143545f43524f5353434841494e5f545846454553000000000000', params[network].crossChainFeesProxy )

    let crossChainFees = await CrossChainFees.at(params[network].crossChainFeesProxy)
    crossChainFees.addChannel(params[network].crossChainProxy)

    // test
    // crossChain test
    const RING = await ERC223.at(params[network].ring);
    const KTON = await ERC223.at(params[network].kton);
    // // approve ring
    await RING.approve(params[network].crossChainFeesProxy, web3.utils.toWei('10000'))
    await KTON.approve(params[network].crossChainFeesProxy, web3.utils.toWei('10000'))
    
    let tx = await RING.transferFrom(accounts[0], params[network].crossChainProxy, web3.utils.toWei('1.2345'), '0xe44664996ab7b5d86c12e9d5ac3093f5b2efc9172cb7ce298cd6c3c51002c318')
    console.log('transfer ring tx:', tx.tx)

    tx = await KTON.transferFrom(accounts[0], params[network].crossChainProxy, web3.utils.toWei('0.0001234'), '0xe44664996ab7b5d86c12e9d5ac3093f5b2efc9172cb7ce298cd6c3c51002c318')
    console.log('transfer kton tx:', tx.tx)
}
