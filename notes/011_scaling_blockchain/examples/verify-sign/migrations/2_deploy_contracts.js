const ReceiverPays = artifacts.require("ReceiverPays");

module.exports = function(deployer) {
  deployer.deploy(ReceiverPays);
};
