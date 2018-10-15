const TokenLocation = artifacts.require('TokenLocation');

const HMETER = 10 ** 8;

contract('Token Location Test', async(accounts) => {
    let deployer = accounts[0];
    let investor = accounts[1];
    let tokenLocation;

    before('deploy and configure', async() => {
        // get contract from deployed version
        tokenLocation     = await TokenLocation.deployed();

        console.log('tokenLocation address: ', tokenLocation.address);
    })

    it('test encode and decode in decimal', async() => {

        let locationId = await tokenLocation.encodeLocationId.call(-49 * HMETER, 49 * HMETER);
        let location = await tokenLocation.decodeLocationId.call(locationId);
        assert.equal(location[0].toNumber(), -49 * HMETER);
        assert.equal(location[1].toNumber(), 49 * HMETER);

        let locationId1 = await tokenLocation.encodeLocationId.call(1, -1);
        console.log("locationId1... " + locationId1);
        let location1 = await tokenLocation.decodeLocationId.call(locationId1);
        assert.equal(location1[0].toNumber(), 1);
        assert.equal(location1[1].toNumber(), -1);

    });

    it('test encode and decode in 100M', async() => {

        let locationId = await tokenLocation.encodeLocationId100M.call(-49, 49);
        let location = await tokenLocation.decodeLocationId100M.call(locationId);
        assert.equal(location[0].toNumber(), -49);
        assert.equal(location[1].toNumber(), 49);

        let locationId1 = await tokenLocation.encodeLocationId100M.call(1, -1);
        console.log("locationId1... " + locationId1);
        let location1 = await tokenLocation.decodeLocationId100M.call(locationId1);
        assert.equal(location1[0].toNumber(), 1);
        assert.equal(location1[1].toNumber(), -1);

    });

})