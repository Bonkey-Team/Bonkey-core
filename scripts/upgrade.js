// scripts/upgrade_box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const CampaignFactory = await ethers.getContractFactory("CampaignFactory");
  console.log("Upgrading CampaignFactory...");
  const factory = await upgrades.upgradeProxy("0x9Bf79cA6d43A25b7b452908064A2d577d214431f", CampaignFactory);
  console.log("CampaignFactory upgraded");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
