const EC = require('elliptic').ec;
const SHA256 = require('crypto-js/sha256');

const ec = new EC('secp256k1');

// TODO: fill in your hex private key
const privateKey = "eccd4f8f5f0e8a61d9dc5f87f273bfa72f091b4e6d77a42d0af1e4681e6f5fa5";

const key = ec.keyFromPrivate(privateKey);

// TODO: change this message to whatever you would like to sign
const message = "Hello World!";

const msgHash = SHA256(message);

const signature = key.sign(msgHash.toString());

console.log({
  message,
  signature: {
    r: signature.r.toString(16),
    s: signature.s.toString(16)
  }
});
