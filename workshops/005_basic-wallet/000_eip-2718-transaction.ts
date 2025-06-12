// LegacyTransaction is rlp([nonce, gasPrice, gasLimit, to, value, data, v, r, s])
import dotenv from "dotenv"
import axios from "axios";
import { bigIntToUnpaddedBytes, bytesToBigInt, bytesToHex, bytesToUnprefixedHex, keccak256 } from "./utils";
import { secp256k1 } from "@noble/curves/secp256k1"
import { intToBytes, toBytes, unpadBytes } from "./bytes-utils";
import { RLP } from "@ethereumjs/rlp"

const rpcUrl = "https://ethereum-holesky-rpc.publicnode.com"

dotenv.config({ path: "./.env" });

async function pollTransaction(txHash: string) {
  let txReceipt = null;
  while (txReceipt === null) {
    console.log("Polling tx receipt for ", txHash)
    const txReceiptRes = await axios.post(rpcUrl, {
      "jsonrpc": "2.0", "method": "eth_getTransactionReceipt", "params": [txHash], "id": 1
    })
    txReceipt = txReceiptRes.data.result
    if (txReceipt === null) {
      await new Promise(resolve => setTimeout(resolve, 1000))
    }
  }
  console.log("txreceipt is available")
  return txReceipt
}

async function main() {
  const privateKey = process.env.EXECUTOR_PRIVATE_KEY as string
  const recipientAddress = process.env.RECIPIENT_ADDRESS as `0x${string}`
  const signerAddress = process.env.EXECUTOR_ADDRESS

  // fetch the latest block : eth_blockNumber
  const blockNumberRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1
  })

  const blockNumber = blockNumberRes.data.result

  // fetch the nonce of the signer : eth_getTransactionCount
  const nonceRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_getTransactionCount", "params": [signerAddress, blockNumber], "id": 1
  })

  const nonce = nonceRes.data.result

  // fetch the gas price : eth_gasPrice
  const gasPriceRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_gasPrice", "params": [], "id": 1
  })

  const gasPrice = gasPriceRes.data.result

  // fetch the balance of the signer Address : eth_getBalance
  const balanceRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_getBalance", "params": [signerAddress, blockNumber], "id": 1
  })

  const balance = BigInt(balanceRes.data.result)

  const value = (BigInt(balance) * BigInt(10)) / BigInt(100)

  const gasLimitRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_estimateGas", "params": [{
      from: signerAddress,
      to: recipientAddress,
      value: `0x${value.toString(16)}`
    }], "id": 1
  })

  const gasLimit = gasLimitRes.data.result

  const chainIdRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1
  })

  const chainId = chainIdRes.data.result

  // rlp the transaction envelope aka serialization
  const rlpEncode = RLP.encode([
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(nonce))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(gasPrice))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(gasLimit))),
    toBytes(recipientAddress),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(value))),
    toBytes("0x"),
    bigIntToUnpaddedBytes(BigInt(chainId)),
    unpadBytes(intToBytes(0)),
    unpadBytes(intToBytes(0))
  ])

  // keccak256 hash of the rlp encoded message

  const keccak256Hash = keccak256(rlpEncode)

  // sign the RLP transaction envelope output
  const signedMessage = secp256k1.sign(keccak256Hash, privateKey, { extraEntropy: true })

  // rlp the transaction envelope aka serialization
  const rlpEncode1 = RLP.encode([
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(nonce))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(gasPrice))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(gasLimit))),
    toBytes(recipientAddress),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(value))),
    toBytes("0x"),
    bigIntToUnpaddedBytes(BigInt(signedMessage.recovery) + BigInt(35) + BigInt(chainId) * BigInt(2)), // For EIP-155 sign recovery >= 35
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(signedMessage.r))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(signedMessage.s)))
  ])

  // broadcast transaction : eth_sendRawTransaction
  const txRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_sendRawTransaction", "params": [bytesToHex(rlpEncode1)], "id": 1
  })

  console.log(txRes.data.result)

  // get the transaction receipt : eth_getTransactionReceipt
  pollTransaction(txRes.data.result).then(console.log)

  // How the ethereum node is able to recover the publickey?
  // // TODO (optional): validate and recover 
  // const res = RLP.decode(bytesToHex(rlpEncode1))

  // res.forEach((ele, index) => {
  //   if (ele instanceof Uint8Array) {
  //     // index => field
  //     //   0    : nonce
  //     //   1    : gasPrice
  //     //   2    : gasLimit
  //     //   3    : recipient address 
  //     //   4    : value
  //     //   5    : data
  //     //   6    : v
  //     //   7    : r
  //     //   8    : s
  //     console.log(Buffer.from(ele).toString("hex"))
  //   }
  // });
  // const sigOb = new secp256k1.Signature(bytesToBigInt(toBytes(signedMessage.r)), bytesToBigInt(toBytes(signedMessage.s)))
  // const sigOb1 = sigOb.addRecoveryBit(Number(signedMessage.recovery))
  // const pubKey = sigOb1.recoverPublicKey(`${bytesToUnprefixedHex(rlpEncode1)}`)
  // const pubKeyBytes = pubKey.toRawBytes(false)
  // console.log("Account ", Buffer.from(keccak256(pubKeyBytes).subarray(-20)).toString("hex"))
}

main()