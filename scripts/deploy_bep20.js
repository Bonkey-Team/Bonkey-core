// scripts/deploy.js
async function main() {
  // We get the contract to deploy
  const BEP20Token = await ethers.getContractFactory("BEP20Token");
  console.log("Deploying BEP20Token...");
  const token = await BEP20Token.deploy();
  await token.deployed();
  console.log("BEP20Token deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});
