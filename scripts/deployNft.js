// scripts/deploy-contract.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contract with deployer address:", deployer.address);
    const Contract = await ethers.getContractFactory("Lock"); 
    const contract = await Contract.deploy();

    await contract.waitForDeployment();

    console.log("Contract address:", await contract.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });