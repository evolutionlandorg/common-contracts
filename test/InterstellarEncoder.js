const InterstellarEncoder = artifacts.require('InterstellarEncoder');

contract('InterstellarEncoder Test', async(accounts) => {
    let interstellarEncoder;

    before('deploy and configure', async() => {
        // get contract from deployed version
        interstellarEncoder     = await InterstellarEncoder.deployed();

        console.log('interstellarEncoder address: ', interstellarEncoder.address);

        await interstellarEncoder.registerNewTokenContract(0x01);

        await interstellarEncoder.registerNewObjectClass(0x0f, 1);
    })

    it('test encode and decode in decimal', async() => {
        let tokenId = await interstellarEncoder.encodeTokenIdForObjectContract(0x01, 0x0f, 3);
        console.log(tokenId.toString(16));

        assert.equal(tokenId, 0x2a01000101000101000000000000000100000000000000000000000000000003);

        let tokenId2 = await interstellarEncoder.encodeTokenId(0x01, 1, 3);

        assert.equal(tokenId.toString(16), tokenId2.toString(16));

        let contractAddress = await interstellarEncoder.getContractAddress.call(tokenId.valueOf());
        console.log(contractAddress);
        assert.equal(contractAddress, 0x01);

        let objectId = await interstellarEncoder.getObjectId.call(tokenId.valueOf());
        assert.equal(objectId, 0x03);

    });
})