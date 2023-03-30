const LongLivedPaymentChannel = artifacts.require("LongLivedPaymentChannel");

contract(
  "Recipient should be able to withdraw amount and then close",
  (accounts) => {
    // declare all global variables here
    let contractInstance;
    let contractAddress;
    let longLivedPaymentChannelTx;
    const skey =
      "dec072ad7e4cf54d8bce9ce5b0d7e95ce8473a35f6ce65ab414faea436a2ee86"; // private key
    web3.eth.accounts.wallet.add(`0x${skey}`);
    const masterAccount = accounts[0];
    const sender = web3.eth.accounts.wallet[0].address;
    const senderSkey = web3.eth.accounts.wallet[0].privateKey;
    const recipient = accounts[1];
    const closeDuration = 200;
    const depositAmount = web3.utils.toWei("2", "ether");
    // sender can open the channel (deploy contract and deposit funds)
    before(async () => {
      await web3.eth.sendTransaction({
        from: masterAccount,
        to: sender,
        value: web3.utils.toWei("5", "ether"),
        gas: 21000,
      });
      contractInstance = new web3.eth.Contract(LongLivedPaymentChannel.abi);
      const gas = await contractInstance
        .deploy({
          data: LongLivedPaymentChannel.bytecode,
          from: sender,
          value: depositAmount,
          arguments: [recipient, closeDuration],
        })
        .estimateGas();
      longLivedPaymentChannelTx = await contractInstance
        .deploy({
          data: LongLivedPaymentChannel.bytecode,
          arguments: [recipient, closeDuration],
        })
        .send({
          from: sender,
          gas,
          value: depositAmount,
        });
      contractAddress = longLivedPaymentChannelTx.options.address;
      const actualSender = await longLivedPaymentChannelTx.methods.sender().call({
        from: recipient,
      });
      const actualRecipient = await longLivedPaymentChannelTx.methods.recipient().call({
        from:accounts[2]
      });
      const actualCloseDuration = await longLivedPaymentChannelTx.methods.closeDuration().call({
        from:accounts[2]
      })
      const actualDepositedAmount = await web3.eth.getBalance(contractAddress);
      // assertions
      assert.equal(actualSender, sender, "Sender is not as expected");
      assert.equal(
        actualDepositedAmount,
        depositAmount,
        "The deposited amount is as expected"
      );
      assert.equal(
        actualRecipient,
        recipient,
        "The recipient is as expected"
      );
      assert.equal(actualCloseDuration,closeDuration,"closeDuration is not as expected")
    });

    it("the recipient should be able to withdraw from the channel", async () => {
    //   // code that will sign for recipient to withdraw
    //   // code that will use this sign as well as recipient as caller of `withdraw` function
    //   // the recipient should be able to close the channel
    //   // make necessary assertions to validate balance of sender and recipient
      const withdrawAmount = web3.utils.toWei("1", "ether");
      const message = web3.utils.soliditySha3(
        { t: "address", v: contractAddress },
        { t: "uint256", v: withdrawAmount }
      );
      const signed = await web3.eth.accounts.sign(message, senderSkey);

      const recipientBalance = await web3.eth.getBalance(recipient);
      const withdrawalTx = await longLivedPaymentChannelTx.methods
        .withdraw(withdrawAmount, signed.signature)
        .send({ from: recipient });

      const trans = await web3.eth.getTransaction(withdrawalTx.transactionHash);
      const transFee = web3.utils
        .toBN(trans.gasPrice)
        .mul(web3.utils.toBN(withdrawalTx.gasUsed));

      const balance = web3.utils.toBN(recipientBalance).add(web3.utils.toBN(withdrawAmount)).sub(web3.utils.toBN(transFee));
      const returnedBalance = await web3.eth.getBalance(recipient);
      assert.equal(balance, returnedBalance, "The balance of recipient is not as expected.");
    });

    it("the recipient should be able to perform channel closure and maintain balance", async () => {

      const withdrawClosureAmount = web3.utils.toWei("1", "ether");
      const signedMsg = web3.utils.soliditySha3(
        { t: "address", v: contractAddress },
        { t: "uint256", v: withdrawClosureAmount }
      );
      const signedResult = await web3.eth.accounts.sign(signedMsg, senderSkey);
      
      const balanceBeforeClosure = await web3.eth.getBalance(recipient);
      const contractBalance = await web3.eth.getBalance(contractAddress);
      const senderBalance = await web3.eth.getBalance(sender);

      const closureTx = await longLivedPaymentChannelTx.methods
        .close(withdrawClosureAmount, signedResult.signature)
        .send({ from: recipient });

      const contractBalanceAfterClose = await web3.eth.getBalance(contractAddress);
      const senderBalanceAfterClose = await web3.eth.getBalance(sender);
      const recAfterClosure = await web3.eth.getBalance(recipient);
      
      const trans = await web3.eth.getTransaction(closureTx.transactionHash);
      const transFees = web3.utils
        .toBN(trans.gasPrice)
        .mul(web3.utils.toBN(closureTx.gasUsed));      

      //const balance = web3.utils.toBN(balanceBeforeClosure).add(web3.utils.toBN(withdrawClosureAmount)).sub(web3.utils.toBN(transFees));
      const balance = web3.utils.toBN(balanceBeforeClosure).sub(web3.utils.toBN(transFees));
      const balanceAfterClosure = await web3.eth.getBalance(recipient);
      assert.equal(balance, balanceAfterClosure, "Recovered fund is not as expected.");
    });
  }
);
