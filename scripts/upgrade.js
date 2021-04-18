// scripts/upgrade_box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const contractName = 'MasterChef';
  const contractAddr = '0x12d86af861Bb2C8465548d3e2db2FED042770cAD';
  // We get the contract to deploy
  const contract = await ethers.getContractFactory(contractName);
  console.log("Upgrading " +  contractName + "...");
  const instance = await upgrades.upgradeProxy(contractAddr, contract);
  console.log(contractName + " upgraded");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
