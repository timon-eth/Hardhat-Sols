/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");
require("@nomicfoundation/hardhat-verify");

const AVALANCHE_TEST_PRIVATE_KEY = "";
const AVALANCHE_MAIN_PRIVATE_KEY = "";

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.4.26"
      },
      {
        version: "0.8.0"
      },
      {
        version: "0.8.19"
      },
      {
        version: "0.8.7"
      },
      {
        version: "0.8.9"
      }
    ]
  },
  networks: {
    avalancheTest: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      gasPrice: 225000000000,
      chainId: 43113,
      accounts: [`0x${AVALANCHE_TEST_PRIVATE_KEY}`]
    },
    avalancheMain: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      gasPrice: 225000000000,
      chainId: 43114,
      accounts: [`0x${AVALANCHE_MAIN_PRIVATE_KEY}`]
    },
    binanceTest:{
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      gasPrice: 20000000000,
      chainId:97,
      accounts: [`0x${AVALANCHE_TEST_PRIVATE_KEY}`]
    }
  },
  etherscan: {
    apiKey: "", // Replace with your BscScan API key
  },
};
