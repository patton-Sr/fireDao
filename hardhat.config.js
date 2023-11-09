
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  paths: {
    sources: "./contracts/nfts", // 这里指定你要编译的文件夹路径
  },
  solidity:{
    compilers:[
      {version:"0.6.12"},
      {version: "0.8.18"},
      {version:"0.8.0"}
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    bscTest: {
      chainId: 421613,
      url: `https://goerli-rollup.arbitrum.io/rpc`,
      accounts: [`1e758b3dbe45a368c7436b23bcb2b4c21e763571796d98b43b7c69d950aac7c3`],
    },
  },
};
