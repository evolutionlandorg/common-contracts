// require('babel-register')({
//   ignore: /node_modules\/(?!openzeppelin-solidity\/test\/helpers)/
// });
// require('babel-polyfill');

var HDWalletProvider = require("truffle-hdwallet-provider");
// Either use this key or get yours at https://infura.io/signup. It's free.
var infura_apikey = "INFURA_APIKEY";
// use your deployer account's mnemonic
var mnemonic = "BLAH * 16";

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: { // ganache by default
      host: "localhost",
      port: 7545,
      gas: 6500000,
      gasPrice: 20000000000,
      from: "xxxx", // default from account setting
      network_id: "5777"
    },
    kovan:  {
      provider: () => new HDWalletProvider(mnemonic, "https://kovan.infura.io/" + infura_apikey),
      network_id: 42,
      gas: 4500000
    },
    rinkeby:  {
      provider: () => new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/" + infura_apikey),
      network_id: 4,
      gas: 4500000
    },
    live: {
    }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  },
  mocha: {
    useColors: true
  }
};

/*
module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    privateNode: {
      host: '127.0.0.1',
      port: 8501,
      network_id: '*'
    },
    ganache: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    ganache_cli: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    }
  }
};
*/