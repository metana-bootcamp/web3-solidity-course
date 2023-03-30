const EC = require('elliptic').ec;
const SHA256 = require('crypto-js/sha256');

const ec = new EC('secp256k1');

// TODO: fill in the public key points
const publicKey = {
  x: "b1da7ed247394eddfc4140f5b4495d410b9847c59d50b68441153b6a5ae6f2e4",
  y: "59bf3244052c8a68193c66e23ba3ee3a1138d931f9d4d109723fbe8dd30a4a1f"
}

const key = ec.keyFromPublic(publicKey, 'hex');

// TODO: change this message to whatever was signed
const msg = "Hello World!";
const msgHash = SHA256(msg).toString();

// TODO: fill in the signature components
const signature = {
  r: "147df34215daae40defc349e4d1a59a83e5d4d80919558fa8991170bf6bd62f0",
  s: "4370cf7b31122272608271f7657b9c158e741f9412ce0484922f7b794bc2f3b4"
};

console.log(key.verify(msgHash, signature));
