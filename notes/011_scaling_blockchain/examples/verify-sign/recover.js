const Web3 = require("web3");

const web3 = new Web3();

// sample signed obj
// {
//   message: "0x1f152501520042d34ab9424b204408f2b26a9f2a9d98f32ec7a8df9dcc1d1695",
//   messageHash:
//     "0x9bcc3ce15980d68eeca0565994101cdf59ed3fba4e35c3f53c879673261d146a",
//   v: "0x1c",                                                                 // Recovery value + 27
//   r: "0x8aed226ff09fba5e800b26ccf1536e24e0a03e79360f22046158e8202b1f10ea",   // First 32 bytes of the signature
//   s: "0x396cdc44a99c36d81cc879fe28bdc9159036ec650b158abf0683ac9c2bd715be",   // Next 32 bytes of the signature
//   signature:
//     "0x8aed226ff09fba5e800b26ccf1536e24e0a03e79360f22046158e8202b1f10ea396cdc44a99c36d81cc879fe28bdc9159036ec650b158abf0683ac9c2bd715be1c",
// };

// option 1
// function recover1() {
//   // https://web3js.readthedocs.io/en/v1.2.7/web3-eth-accounts.html#recover
//   const sigObj = {
//     messageHash:
//       "0x9bcc3ce15980d68eeca0565994101cdf59ed3fba4e35c3f53c879673261d146a",
//     v: "0x1c",
//     r: "0x8aed226ff09fba5e800b26ccf1536e24e0a03e79360f22046158e8202b1f10ea",
//     s: "0x396cdc44a99c36d81cc879fe28bdc9159036ec650b158abf0683ac9c2bd715be",
//   };
//   const recoveredAddress = web3.eth.accounts.recover(sigObj);
//   console.log(recoveredAddress);
// }

// option 2
function recover2() {
  // https://web3js.readthedocs.io/en/v1.2.7/web3-eth-accounts.html#recover
  // const message =
  //   "0x1f152501520042d34ab9424b204408f2b26a9f2a9d98f32ec7a8df9dcc1d1695";
  const message =
    "0xa663f3e75af7adad2df2b412a56c8c7e2f3cee9e058592b4ff1701df48b90346";
  // const sig =
  //   "0x8aed226ff09fba5e800b26ccf1536e24e0a03e79360f22046158e8202b1f10ea396cdc44a99c36d81cc879fe28bdc9159036ec650b158abf0683ac9c2bd715be1c";
  const sig =
    "0x5370af66e64242357e4e38c637e3720d05d10b41492788c785cf485d9fe7bac0134c3b6e48ef600ba7695ad1598df29739d6f55c50a52eca5731f2118a6b458b1b";
  const recoveredAddress = web3.eth.accounts.recover(message, sig);
  console.log(recoveredAddress);
}

// option 3
// function recover3() {
//   // https://web3js.readthedocs.io/en/v1.2.7/web3-eth-accounts.html#recover
//   const message =
//     "0x1f152501520042d34ab9424b204408f2b26a9f2a9d98f32ec7a8df9dcc1d1695";
//   const v = "0x1c";
//   const r =
//     "0x8aed226ff09fba5e800b26ccf1536e24e0a03e79360f22046158e8202b1f10ea";
//   const s =
//     "0x396cdc44a99c36d81cc879fe28bdc9159036ec650b158abf0683ac9c2bd715be";
//   const recoveredAddress = web3.eth.accounts.recover(message, v,r,s);
//   console.log(recoveredAddress);
// }

recover2();
