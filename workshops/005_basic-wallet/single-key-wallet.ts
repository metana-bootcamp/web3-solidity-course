import { keccak256, randomBytesFn } from "./utils"
import { secp256k1 } from "@noble/curves/secp256k1"
import { Buffer } from "buffer"

async function main() {
    const privateKey = randomBytesFn(32)
    console.log("Private Key : ", Buffer.from(privateKey).toString("hex"))
    // pubkey
    const pubKey  = secp256k1.ProjectivePoint.fromPrivateKey(privateKey).toRawBytes(false).slice(1) // secp256k1 elliptic curve
    console.log("Public Key : ", Buffer.from(pubKey).toString("hex"))
    // account address
    console.log("Account ", Buffer.from(keccak256(pubKey).subarray(-20)).toString("hex"))
}
main()

// Private Key :  106564317a880f4e4a5a0364793300aac0d067cd750bba9f39bf625428c8cc5a
// Public Key :  c7778f6165b8cbeba6abd690801a845d2ab9f677c6aa1e10c51861d0b8c9e774b0c0d350e3ea3854dc24a90fd84745b217d90528834b9c457f4f9792e76c9db8
// Account  1e1ffc8f88efb45e361a2137561acc08a5a4c665