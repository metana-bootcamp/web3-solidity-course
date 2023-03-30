const SimplePaymentChannel = artifacts.require("SimplePaymentChannel");

module.exports = function(deployer,network,accounts) {
  deployer.deploy(SimplePaymentChannel,accounts[1],200,{from:accounts[0],value:web3.utils.toWei("5","ether")});
};
