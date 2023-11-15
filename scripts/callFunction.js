// batchCallContracts.js

async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log(`Calling contracts with address: ${deployer.address}`);
  
    const YourContract = await ethers.getContractFactory("Red");
  
    const methodName = "setBaseURI";
  
    const contractAddresses =["0x021135d663F8EbFA3ca30A728fC45B720be1C2Bb",

    "0xCA8F97684f606E242e41906033143391fa2152a6","0x57510fA55a4aEdB2175202CA348ABbB2777E21D7","0x93fAf7868F28E943BbE932D874f61877BC453d59","0xA1B0ea1E130f9CB7A380E8adBD453cb90F61a035","0x5C2C2ac3F8CF1B18694C56E7Ac9AD39A3725ACF4","0xb6D115B2805A94d95C74a1DC4084472bD83118Cf"];
  
    for (const contractAddress of contractAddresses) {
      console.log(`Calling ${methodName} on contract at address: ${contractAddress}...`);
  
      const yourContractInstance = await YourContract.attach(contractAddress);
      const result = await yourContractInstance[methodName]("");
  
      console.log(`${methodName} result from ${contractAddress}: ${result}`);
    }
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  