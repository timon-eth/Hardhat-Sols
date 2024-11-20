
async function main() {
    //...existing code...
    const [deployer] = await ethers.getSigners();
    const Vesting = await ethers.getContractFactory("Vesting");
    const vestingContract = await Vesting.deploy("0xA6DD74936b88739366065F7B3B5C95852bf57F2B");
    console.log(vestingContract.contracts)
    saveDAppFiles(vestingContract);
}

// Store metadata for the dApp
function saveDAppFiles(contract) {
    const fs = require("fs");
    const contractsDir = __dirname + "/../client/src/contracts";

    if (!fs.existsSync(contractsDir)) {
        fs.mkdirSync(contractsDir);
    }

    // Store the contract address
    const addressFileName = contractsDir + "/bnbswap-address.json";
    fs.writeFileSync(
        addressFileName,
        JSON.stringify({ Contract: contract.address }, undefined, 2)
    );
    console.log("Stored address in ", addressFileName);

    // Store the contract artifact (including the ABI)
    const ContractArtifact = artifacts.readArtifactSync("BNBsmartswap");
    const artifactFileName = contractsDir + "/BNBsmartswap.json";
    fs.writeFileSync(
        artifactFileName,
        JSON.stringify(ContractArtifact, null, 2)
    );
    console.log("Stored artifact in ", artifactFileName);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
