// scripts/deploy_upgradeable_factory.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const BonkeyFactory = await ethers.getContractFactory("BonkeyFactory");
  console.log("Deploying BonkeyFactory...");
  const factory = await upgrades.deployProxy(BonkeyFactory);
  await factory.deployed();
  console.log("BonkeyFactory deployed to:", factory.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
