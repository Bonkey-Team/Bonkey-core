// scripts/deploy.js
async function main() {
  // We get the contract to deploy
  const Project = await ethers.getContractFactory("Project");
  console.log("Deploying Project...");
  const project = await Project.deploy();
  await project.deployed();
  console.log("Project deployed to:", project.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});
