/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.4.25"
      },
      {
        version: "0.6.10", 
      },
      {
        version: "0.7.6", 
      }
    ]
  },
  networks:{
    hardhat:{
      forking:{
        url:process.env.FORKING_URL,
        blockNumber:11236709 
      }
    }
  }
};
