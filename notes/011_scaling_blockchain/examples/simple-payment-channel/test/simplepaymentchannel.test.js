const SimplePaymentChannel = artifacts.require("SimplePaymentChannel");

contract(
  "SimplePaymentChannel",
  (accounts) => {
    // declare all global variables here
    let contractInstance;
    let contractAddress;
    let simplePaymentChannelTx;
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
    beforeEach(async () => {
      await web3.eth.sendTransaction({
        from: masterAccount,
        to: sender,
        value: web3.utils.toWei("5", "ether"),
        gas: 21000,
      });
      contractInstance = new web3.eth.Contract(SimplePaymentChannel.abi);
      const gas = await contractInstance
        .deploy({
          data: SimplePaymentChannel.bytecode,
          from: sender,
          value: depositAmount,
          arguments: [recipient, closeDuration],
        })
        .estimateGas();
      data = await contractInstance
        .deploy({
          data: SimplePaymentChannel.bytecode,
          arguments: [recipient, closeDuration],
        }).encodeABI()

      simplePaymentChannelTx = await web3.eth.sendTransaction({
        from: sender,
        gas: gas + 100000,
        value: depositAmount,
        data
      });
      const deployedTime = (await web3.eth.getBlock(simplePaymentChannelTx.blockNumber)).timestamp
      contractAddress = simplePaymentChannelTx.contractAddress;
      contractInstance = new web3.eth.Contract(SimplePaymentChannel.abi, contractAddress)
      const actualSender = await contractInstance.methods.sender().call({
        from: recipient,
      });
      const actualRecipient = await contractInstance.methods.recipient().call({
        from: accounts[2]
      });
      const actualCloseDuration = await contractInstance.methods.expiration().call({
        from: accounts[2]
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
      assert.equal(actualCloseDuration, closeDuration + deployedTime, "closeDuration is not as expected")
    });

    it("the recipient should be able to withdraw and close the channel", async () => {
      // code that will sign for recipient to withdraw
      // code that will use this sign as well as recipient as caller of `withdraw` function
      // the recipient should be able to close the channel
      // make necessary assertions to validate balance of sender and recipient
      const withdrawAmount = web3.utils.toWei("1", "ether");
      const message = web3.utils.soliditySha3(
        { t: "address", v: contractAddress },
        { t: "uint256", v: withdrawAmount }
      );
      const signed = await web3.eth.accounts.sign(message, senderSkey);

      const recipientBalance = await web3.eth.getBalance(recipient);
      const withdrawalTx = await contractInstance.methods
        .close(withdrawAmount, signed.signature).send({ from: recipient })

      const trans = await web3.eth.getTransaction(withdrawalTx.transactionHash);
      const transFee = web3.utils
        .toBN(trans.gasPrice)
        .mul(web3.utils.toBN(withdrawalTx.gasUsed));

      const balance = web3.utils.toBN(recipientBalance).add(web3.utils.toBN(withdrawAmount)).sub(web3.utils.toBN(transFee));
      const returnedBalance = await web3.eth.getBalance(recipient);
      assert.equal(balance, returnedBalance, "The balance of recipient is not as expected.");
    });
  }
);
