// scripts/upgrade_box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const BonkeyFactory = await ethers.getContractFactory("BonkeyFactory");
  console.log("Upgrading BonkeyFactory...");
  const factory = await upgrades.upgradeProxy("0xeBA1566506Fa63466E3028CFF33000D3f8B4BDe0", BonkeyFactory);
  console.log("BonkeyFactory upgraded");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
