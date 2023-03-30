const ReceiverPays = artifacts.require("ReceiverPays");
const BigNumber = require("bignumber.js");
contract("ReceiverPays", (accounts) => {
  const skey =
    "dec072ad7e4cf54d8bce9ce5b0d7e95ce8473a35f6ce65ab414faea436a2ee86";
  web3.eth.accounts.wallet.add(`0x${skey}`);
  const masterAccount = accounts[0];
  const owner = web3.eth.accounts.wallet[0].address;
  const ownerSkey = web3.eth.accounts.wallet[0].privateKey;
  const receiver = accounts[1];
  const depositedAmount = web3.utils.toWei("2", "ether");
  const recipientClaimAmount = web3.utils.toWei("1", "ether");
  const nonce = "0"; // check number
  it("the receiver should be able to able to claim if signature is verified", async () => {
    await web3.eth.sendTransaction({
      from: masterAccount,
      to: owner,
      value: web3.utils.toWei("5", "ether"),
      gas: 21000,
    });
    const receiverPaysInstance = new web3.eth.Contract(ReceiverPays.abi);
    const gas = await receiverPaysInstance
      .deploy({
        data: ReceiverPays.bytecode,
        from: owner,
        value: depositedAmount,
      })
      .estimateGas();
    const receiverPaysTx = await receiverPaysInstance
      .deploy({ data: ReceiverPays.bytecode })
      .send({
        from: owner,
        gas:gas+100000,
        value: depositedAmount,
      });
    const contractAddress = receiverPaysTx.options.address;
    const actualOwner = await receiverPaysTx.methods.owner().call({
      from: receiver,
    });
    const actualDepositedAmount = await web3.eth.getBalance(contractAddress);
    assert.equal(actualOwner, owner, "Owner is not as expected");
    assert.equal(
      actualDepositedAmount,
      depositedAmount,
      "The deposited amount is as expected"
    );
    // writing a check to the recipient to withdraw say  1 Ether
    const message = web3.utils.soliditySha3(
      { t: "address", v: receiver },
      { t: "uint256", v: recipientClaimAmount },
      { t: "uint256", v: nonce },
      { t: "address", v: contractAddress }
    );
    const sig = await web3.eth.accounts.sign(message, ownerSkey);
    // owner gives the signed message to recipient(e.g. email)
    // recipient will use the signed message to claim the amount
    const receiverBalance = await web3.eth.getBalance(receiver);
    const claimPaymentTx = await receiverPaysTx.methods
      .claimPayment(recipientClaimAmount, nonce, sig.signature)
      .send({ from: receiver });
    const trx = await web3.eth.getTransaction(claimPaymentTx.transactionHash);
    const transactionFee = web3.utils
      .toBN(trx.gasPrice)
      .mul(web3.utils.toBN(claimPaymentTx.gasUsed));
    const calculatedReceiverBalance = web3.utils
      .toBN(receiverBalance)
      .add(web3.utils.toBN(recipientClaimAmount))
      .sub(web3.utils.toBN(transactionFee));
    const receiverNewBalance = await web3.eth.getBalance(receiver);
    assert.equal(
      calculatedReceiverBalance,
      receiverNewBalance,
      "The balance of receiver is not as expected."
    );
  });
});
