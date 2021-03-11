// scripts/deploy_upgradeable_factory.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const CampaignFactory = await ethers.getContractFactory("CampaignFactory");
  console.log("Deploying CampaignFactory...");
  const factory = await upgrades.deployProxy(CampaignFactory,  [42], {initializer: 'store'});
  await factory.deployed();
  console.log("CampaignFactory deployed to:", factory.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
