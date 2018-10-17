const LocationCoder = artifacts.require('LocationCoder');

const HMETER = 10 ** 8;

contract('Token Location Test', async(accounts) => {
    let deployer = accounts[0];
    let investor = accounts[1];
    let locationCoder;

    before('deploy and configure', async() => {
        // get contract from deployed version
        locationCoder     = await LocationCoder.deployed();

        console.log('locationCoder address: ', locationCoder.address);
    })

    it('test encode and decode in decimal', async() => {

        let locationId = await locationCoder.encodeLocationIdXY.call(-49 * HMETER, 49 * HMETER);
        let location = await locationCoder.decodeLocationIdXY.call(locationId);
        assert.equal(location[0].toNumber(), -49 * HMETER);
        assert.equal(location[1].toNumber(), 49 * HMETER);

        let locationId1 = await locationCoder.encodeLocationIdXY.call(1, -1);
        console.log("locationId1... " + locationId1);
        let location1 = await locationCoder.decodeLocationIdXY.call(locationId1);
        assert.equal(location1[0].toNumber(), 1);
        assert.equal(location1[1].toNumber(), -1);

    });

    it('test encode and decode in 100M', async() => {

        let locationId = await locationCoder.encodeLocationIdHM.call(-49, 49);
        let location = await locationCoder.decodeLocationIdHM.call(locationId);
        assert.equal(location[0].toNumber(), -49);
        assert.equal(location[1].toNumber(), 49);

        let locationId1 = await locationCoder.encodeLocationIdHM.call(1, -1);
        console.log("locationId1... " + locationId1);
        let location1 = await locationCoder.decodeLocationIdHM.call(locationId1);
        assert.equal(location1[0].toNumber(), 1);
        assert.equal(location1[1].toNumber(), -1);

    });

    it('test encode and decode 3d points', async() => {

        let locationId = await locationCoder.encodeLocationId3D.call(-49, 49, -1);
        let location = await locationCoder.decodeLocationId3D.call(locationId);
        assert.equal(location[0].toNumber(), -49);
        assert.equal(location[1].toNumber(), 49);
        assert.equal(location[2].toNumber(), -1);

    });


})