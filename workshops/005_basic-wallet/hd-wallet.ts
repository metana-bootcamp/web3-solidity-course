import * as bip39 from '@scure/bip39';
import { wordlist } from '@scure/bip39/wordlists/english';
import { HDKey } from '@scure/bip32';
import { Buffer } from "buffer"
import { secp256k1 } from "@noble/curves/secp256k1"
import { keccak256 } from './utils';


async function main() {
    // // Generate x random words. Uses Cryptographically-Secure Random Number Generator.
    // const mn = bip39.generateMnemonic(wordlist); // bip-39
    // console.log(mn);
    // Irreversible: Uses KDF to derive 64 bytes of key data from mnemonic + optional password.
    const seed = await bip39.mnemonicToSeed("indoor luggage ready glory seven carpet edit trick brand cart salute fold");

    const hdkey = HDKey.fromMasterSeed(seed);
    console.log("Generating Wallet at index 0...")
    const wallet0 = hdkey.derive("m/44'/60'/0'/0/0") // bip-44 (HD Path)
    const pKey: Uint8Array = wallet0.privateKey as Uint8Array
    const publicKey: Uint8Array = wallet0.publicKey as Uint8Array
    console.log("Private Key : ", Buffer.from(pKey).toString("hex"))
    console.log("Public Key : ", Buffer.from(publicKey).toString("hex"))

    const pubKey = secp256k1.ProjectivePoint.fromHex(publicKey).toRawBytes(false).slice(1) // secp256k1 elliptic curve
    console.log("Account ", Buffer.from(keccak256(pubKey).subarray(-20)).toString("hex"))
}
// generate mnemonic
// indoor luggage ready glory seven carpet edit trick brand cart salute fold
// generate wallet
// pk : fa194666d771f886032b2a7af598c24b7e199605278c7d2dc1442845df71af3f
// pubKey : 024ca826a31561552751f3ac1b385eb7f05dadc0c834ac2f3655e444be8149912d
// keccak256 hash of pubKey : 0xe70a75cd8a7bf72df3074a3d949ba00494cd90c31de086056778d4aaf0562049
// account address : keccak256() 0x64003aB2Fd89386F2338B434f46fC91Dbb352221

main()