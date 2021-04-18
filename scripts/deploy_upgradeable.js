// scripts/deploy_bep20.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const contractName = 'MasterChef';
  // We get the contract to deploy
  const contract = await ethers.getContractFactory(contractName);
  console.log("Deploying " + contractName + "...");
  const contractInstance = await upgrades.deployProxy(contract);
  await contractInstance.deployed();
  console.log(contractName + "deployed to:", contractInstance.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});
