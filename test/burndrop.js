const StandardERC223 = artifacts.require('StandardERC223')
const DeployAndTest = artifacts.require("./DeployAndTest.sol")
const TokenBurnDrop = artifacts.require("TokenBurnDrop")
const SettingsRegistry = artifacts.require("SettingsRegistry")

const log = console.log

function toWei(ether) {
    if(ether == 0) {
        return '0'
    }
    return `${ether}000000000000000000`
}


function mine () {
    const id = Date.now()
    return new Promise((resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_mine',
            id: id ,
        }, (err, res) => {
            return err ? reject(err) : resolve(res)
        })
    })
}

contract('Burndrop Bank Test', async (accounts) => {
    let deployer = accounts[0]
    let investor = accounts[1]
    let investor2 = accounts[2]
    let registry
    let ring
    let kton

    async function printBalance(ring, kton, user) {
        log(`${user} -> ring balance: ${await ring.balanceOf(user)}, kton balance: ${await kton.balanceOf(user)}`)
    }

    before('config', async () => {
        const deployAndTest = await DeployAndTest.deployed()
        ring = await StandardERC223.at(await deployAndTest.testRING.call())
        kton = await StandardERC223.at(await deployAndTest.testKTON.call())

        log(`ring: ${ring.address}, kton: ${kton.address}`)

        await ring.mint(investor, toWei(10000))
        await kton.mint(investor2, toWei(10000))

        await printBalance(ring, kton, investor)
        await printBalance(ring, kton, investor2)
    })

    it('burndrop balance', async () => {
        const tokenBurnDrop = await TokenBurnDrop.deployed()
        log('tokenBurndrop:', tokenBurnDrop.address)
        assert.strictEqual((await ring.balanceOf(investor)).toString(), toWei(10000))
        assert.strictEqual((await kton.balanceOf(investor2)).toString(), toWei(10000))

        log(await web3.eth.getBlockNumber())
        await mine()
        log(await web3.eth.getBlockNumber())
        await ring.transfer(tokenBurnDrop.address, toWei(3000), {from: investor})
        await kton.transfer(tokenBurnDrop.address, toWei(4000), {from: investor2})

        await printBalance(ring, kton, investor)
        await printBalance(ring, kton, investor2)

        // assert.strictEqual((await ring.balanceOf(investor)).toString(), toWei(7000), 'ring balance')
        // assert.strictEqual((await kton.balanceOf(investor2)).toString(), toWei(6000), 'kton balance')
        //
        // assert.strictEqual((await ring.balanceOf(tokenBurnDrop.address)).toString(), toWei(0), 'ring balance')
        // assert.strictEqual((await kton.balanceOf(tokenBurnDrop.address)).toString(), toWei(0), 'kton balance')

        await ring.transfer(tokenBurnDrop.address, toWei(3000), {from: investor})
        await kton.transfer(tokenBurnDrop.address, toWei(4000), {from: investor2})

        await printBalance(ring, kton, tokenBurnDrop.address)


    })
})
