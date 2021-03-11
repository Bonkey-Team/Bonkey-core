// scripts/deploy.js
async function main() {

    const libraryFactory = await ethers.getContractFactory(
        "TestLibrary"
    );
    const library = await libraryFactory.deploy();

    const safeMath = await ethers.getContractFactory(
        "SafeMath0"
    );
    const libSafeMath = await safeMath.deploy();

    const contractFactory = await ethers.getContractFactory(
        "TestContractLib",
        { libraries: { 
                TestLibrary: library.address, 
                SafeMath0 : libSafeMath.address 
            } 
        }
    );
    const contract = await contractFactory.deploy();
    console.log(contract.address)

    const contractFactory1 = await ethers.getContractFactory(
        "TestContractLib1",
    );
    const contract1 = await contractFactory1.deploy();
    console.log(contract1.address)

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
