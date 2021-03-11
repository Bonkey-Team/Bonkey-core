// hardhat.config.js
//
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
const { projectId, mnemonic } = require('./secrets.json');

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: {
        version: "0.5.16",
        settings: {
            optimizer: {
                enabled: true,
                runs: 1000
            }
        }
    },
    networks: {
        mainnet: {
            url: `https://mainnet.infura.io/v3/${projectId}`,
            accounts: {mnemonic: mnemonic}
        },
        rinkeby: {
            url: `https://rinkeby.infura.io/v3/${projectId}`,
            accounts: {mnemonic: mnemonic}
        },
        bsc_test: {
            url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
            accounts: {mnemonic: mnemonic}
        }
    },
};
