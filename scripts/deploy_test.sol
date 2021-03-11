// scripts/deploy.js
async function main() {

const libraryFactory = await ethers.getContractFactory(
              "TestLibrary"
            );
            const library = await libraryFactory.deploy();

const contractFactory = await ethers.getContractFactory(
              "TestContractLib",
              { libraries: { TestLibrary: library.address } }
            );
            const contract = await contractFactory.deploy();
            console.log(contract.address)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});
