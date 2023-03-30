# GSN v3 integration workshop

This sample dapp emits an event with the last account that clicked on the "capture the flag" button. We will integrate
this dapp to work gaslessly with GSN v3. This will allow an externally owned account without ETH to capture the flag by
signing a meta transaction.

### To run the sample:

1. first clone and `yarn install`
2. run `yarn gsn-with-ganache` to start a node, and also deploy GSN contracts and start a relayer service.
3. Make sure you have Metamask installed, and pointing to "localhost"
4. run `truffle init`
5. In a different window, run `yarn start`, to deploy the contract, and start the UI
6. Start a browser pointing to "http://localhost:3000"
7. Click the "Capture the Flag" button. Notice that you don't need eth in your account: You only sign the transaction.

## Original credits

* [2-workshop-with-gsn](https://github.com/opengsn/workshop/tree/2-workshop-with-gsn)