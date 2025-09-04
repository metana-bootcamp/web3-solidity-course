// 0x01 || rlp([chainId, nonce, gasPrice, gasLimit, to, value, data, accessList, signatureYParity, signatureR, signatureS])
import dotenv from "dotenv"
import axios from "axios";
import { bigIntToUnpaddedBytes, bytesToBigInt, bytesToHex, bytesToUnprefixedHex, keccak256 } from "./utils";
import { secp256k1 } from "@noble/curves/secp256k1"
import { intToBytes, toBytes, unpadBytes } from "./bytes-utils";
import { RLP } from "@ethereumjs/rlp"
import { concatBytes, hexToBytes, PrefixedHexString } from '@ethereumjs/util'

const rpcUrl = "https://ethereum-holesky-rpc.publicnode.com"

dotenv.config({ path: "./.env" });

export type TransactionType = (typeof TransactionType)[keyof typeof TransactionType]

export const TransactionType = {
  Legacy: 0,
  AccessListEIP2930: 1,
  FeeMarketEIP1559: 2,
  BlobEIP4844: 3,
  EOACodeEIP7702: 4,
} as const

export function txTypeBytes(txType: TransactionType): Uint8Array {
  return hexToBytes(`0x${txType.toString(16).padStart(2, '0')}`)
}

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

export type AccessListItem = {
  address: PrefixedHexString
  storageKeys: PrefixedHexString[]
}

export type AccessList = AccessListItem[]

function accessListJsonToBytes(accessList: AccessList) {
  return accessList.map((item) => [
    hexToBytes(item.address),
    item.storageKeys.map((key) => hexToBytes(key)),
  ])
}

async function main() {
  const privateKey = process.env.EXECUTOR_PRIVATE_KEY as string
  const calculatorCaller = "0x1A2CcB65c2D6E582114a0e12f10b267B060C083A"
  const calculator = "0x48da88102e0a2dC83C4BDaA1A754e80Fb481cFab"
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

  const value = BigInt(0) //(BigInt(balance) * BigInt(10)) / BigInt(100)

  const gasLimitRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_estimateGas", "params": [{
      from: signerAddress,
      to: calculatorCaller,
      data: "0x28b5e32b",
      value: `0x${value.toString(16)}`
    }], "id": 1
  })

  const gasLimit = gasLimitRes.data.result

  const chainIdRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1
  })

  const chainId = chainIdRes.data.result

  // fetch the fee histiry : eth_maxPriorityFeePerGas
  const feeHistoryRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_feeHistory", "params": ["0x1", "latest", []], "id": 1
})
  const feeHistory = feeHistoryRes.data.result
  console.log("feeHistory ", feeHistory)

  // chainId
  // nonce
  // max_prio
  // max_fee
  // gaslimit
  // destination
  // amount
  // data
  // access_list
  // sig y
  // sign r
  // sig s
  // rlp the transaction envelope aka serialization
  const rlpEncode = RLP.encode([
    bigIntToUnpaddedBytes(BigInt(chainId)),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(nonce))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes("0x1"))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(feeHistory.baseFeePerGas[1]))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(gasLimit))),
    toBytes(calculatorCaller),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes("0x0"))),
    toBytes("0x28b5e32b"),
    accessListJsonToBytes([
      {
        address: calculator,
        storageKeys: [
          '0x0000000000000000000000000000000000000000000000000000000000000000',
          '0x0000000000000000000000000000000000000000000000000000000000000001',
        ],
      },
    ]),
    // unpadBytes(intToBytes(0)),
    // unpadBytes(intToBytes(0))
    // new Uint8Array(0),
    // new Uint8Array(0),
    // new Uint8Array(0)
  ])

  // keccak256 hash of the rlp encoded message

  const keccak256Hash = keccak256(concatBytes(txTypeBytes(2), rlpEncode))

  // sign the RLP transaction envelope output
  const signedMessage = secp256k1.sign(keccak256Hash, privateKey, { extraEntropy: true })

  // rlp the transaction envelope aka serialization
  const rlpEncode1 = RLP.encode([
    bigIntToUnpaddedBytes(BigInt(chainId)),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(nonce))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes("0x1"))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(feeHistory.baseFeePerGas[1]))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(gasLimit))),
    toBytes(calculatorCaller),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes("0x0"))),
    toBytes("0x28b5e32b"),
    accessListJsonToBytes([
      {
        address: calculator,
        storageKeys: [
          '0x0000000000000000000000000000000000000000000000000000000000000000',
          '0x0000000000000000000000000000000000000000000000000000000000000001',
        ],
      },
    ]),
    bigIntToUnpaddedBytes(BigInt(signedMessage.recovery)), // + BigInt(35) + BigInt(chainId) * BigInt(2)), // For EIP-155 sign recovery >= 35
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(signedMessage.r))),
    bigIntToUnpaddedBytes(bytesToBigInt(toBytes(signedMessage.s)))
  ])

  // broadcast transaction : eth_sendRawTransaction
  const txRes = await axios.post(rpcUrl, {
    "jsonrpc": "2.0", "method": "eth_sendRawTransaction", "params": [bytesToHex(concatBytes(txTypeBytes(2), rlpEncode1))], "id": 1
  })

  console.log(txRes.data)

  // get the transaction receipt : eth_getTransactionReceipt
  pollTransaction(txRes.data.result).then(console.log)
}

main()

// https://holesky.etherscan.io/tx/0xfe8228cdfdaf90ff6a709c7d0512095d0827c742dba5acc1520077277e25ea77