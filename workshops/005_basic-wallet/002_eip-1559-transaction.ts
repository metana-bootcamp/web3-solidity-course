// 0x02 || rlp([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination, amount, data, access_list, signature_y_parity, signature_r, signature_s])
import dotenv from "dotenv"
import axios from "axios";
import { bigIntToUnpaddedBytes, bytesToBigInt, bytesToHex, bytesToUnprefixedHex, keccak256 } from "./utils";
import { secp256k1 } from "@noble/curves/secp256k1"
import { intToBytes, toBytes, unpadBytes } from "./bytes-utils";
import { RLP } from "@ethereumjs/rlp"
import { concatBytes, hexToBytes } from '@ethereumjs/util'

dotenv.config({ path: "./.env" });

const rpcUrl = "https://ethereum-holesky-rpc.publicnode.com"


export function txTypeBytes(txType: TransactionType): Uint8Array {
    return hexToBytes(`0x${txType.toString(16).padStart(2, '0')}`)
}

export type TransactionType = (typeof TransactionType)[keyof typeof TransactionType]

export const TransactionType = {
    Legacy: 0,
    AccessListEIP2930: 1,
    FeeMarketEIP1559: 2,
    BlobEIP4844: 3,
    EOACodeEIP7702: 4,
} as const

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

    // fetch the max priority fees : eth_maxPriorityFeePerGas
    const maxPriorityFeeRes = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_maxPriorityFeePerGas", "params": [], "id": 1
    })

    const maxPrioFee = maxPriorityFeeRes.data.result

    // fetch the fee histiry : eth_maxPriorityFeePerGas
    const feeHistoryRes = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_feeHistory", "params": ["0x1", "latest", []], "id": 1
    })

    const feeHistory = feeHistoryRes.data.result
    console.log("feeHistory ", feeHistory)

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
        toBytes(recipientAddress),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes(value))),
        toBytes("0x"),
        [],
    ])

    // keccak256 hash of the rlp encoded message

    const keccak256Hash = keccak256(concatBytes(txTypeBytes(2), rlpEncode))

    // sign the RLP transaction envelope output
    const signedMessage = secp256k1.sign(keccak256Hash, privateKey, { extraEntropy: true })

    //   // rlp the transaction envelope aka serialization
    const rlpEncode1 = RLP.encode([
        bigIntToUnpaddedBytes(BigInt(chainId)),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes(nonce))),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes("0x1"))),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes(feeHistory.baseFeePerGas[1]))),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes(gasLimit))),
        toBytes(recipientAddress),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes(value))),
        toBytes("0x"),
        [],
        bytesToBigInt(toBytes(BigInt(signedMessage.recovery))),
        bytesToBigInt(toBytes(BigInt(signedMessage.r))),
        bytesToBigInt(toBytes(BigInt(signedMessage.s))),
    ])
    // broadcast transaction : eth_sendRawTransaction
    const txRes = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_sendRawTransaction", "params": [bytesToHex(concatBytes(txTypeBytes(2), rlpEncode1))], "id": 1
    })

    console.log(txRes.data.result)
    // get the transaction receipt : eth_getTransactionReceipt
    pollTransaction(txRes.data.result).then(console.log)
}

main()