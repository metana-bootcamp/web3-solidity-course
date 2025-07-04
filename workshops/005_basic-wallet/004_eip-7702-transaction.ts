// https://eips.ethereum.org/EIPS/eip-7702 - set as EOA as Contract Account
// https://eips.ethereum.org/EIPS/eip-3074 - AUTH and AUTCALL

// 0x04 || rlp([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination, value, data, access_list, authorization_list, signature_y_parity, signature_r, signature_s])
import dotenv from "dotenv"
import axios from "axios";
import { bigIntToUnpaddedBytes, bytesToBigInt, bytesToHex, bytesToUnprefixedHex, keccak256, numberToHex } from "./utils";
import { secp256k1 } from "@noble/curves/secp256k1"
import { intToBytes, toBytes, unpadBytes } from "./bytes-utils";
import { RLP } from "@ethereumjs/rlp"
import { concatBytes, hexToBytes, PrefixedHexString, setLengthLeft } from '@ethereumjs/util'

dotenv.config({ path: "./.env" });

const rpcUrl = "https://ethereum-holesky-rpc.publicnode.com"
// const rpcUrl = "https://ethereum-sepolia-rpc.publicnode.com"

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
    AuthEIP7702: 5
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
    const executorPrivateKey = process.env.EXECUTOR_PRIVATE_KEY as string
    const txSignerPrivateKey = process.env.TX_SIGNER_PRIVATE_KEY as string
    const executorAddress = process.env.EXECUTOR_ADDRESS
    const txSignerAddress = process.env.TX_SIGNER_ADDRESS as PrefixedHexString
    const helloWorld = "0x978bdF11c8CE071d051025060d96DA8A70749B1D"; // holesky
    // const erc20 = "0x7873a126cD062e159967b003036F3FDc4dcb8Aaf" // holesky
    // const erc20 = "0x5A18f3Ccc309F769b671c9b5246c72FBA14f4b99" // sepolia

    // fetch the latest block : eth_blockNumber
    const blockNumberRes = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1
    })

    const blockNumber = blockNumberRes.data.result

    // fetch the nonce of the signer : eth_getTransactionCount
    const nonceRes = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_getTransactionCount", "params": [executorAddress, blockNumber], "id": 1
    })

    const nonce = nonceRes.data.result

    // fetch the nonce of the signer : eth_getTransactionCount
    const nonceResTxSigner = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_getTransactionCount", "params": [txSignerAddress, blockNumber], "id": 1
    })

    const nonceTxSigner = nonceResTxSigner.data.result
    // const nonceTxSigner = "0x01" 

    // fetch the max priority fees : eth_maxPriorityFeePerGas
    const maxPriorityFeeRes = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_maxPriorityFeePerGas", "params": [], "id": 1
    })

    const maxPrioFee = maxPriorityFeeRes.data.result

    // fetch the fee history : eth_maxPriorityFeePerGas
    const feeHistoryRes = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_feeHistory", "params": ["0x1", "latest", []], "id": 1
    })

    const feeHistory = feeHistoryRes.data.result
    console.log("feeHistory ", feeHistory)

    // // fetch the balance of the signer Address : eth_getBalance
    // const balanceRes = await axios.post(rpcUrl, {
    //     "jsonrpc": "2.0", "method": "eth_getBalance", "params": [executorAddress, blockNumber], "id": 1
    // })

    // const balance = BigInt(balanceRes.data.result)

    // const value = (BigInt(balance) * BigInt(10)) / BigInt(100)

    // fetch the chainId : eth_chainId
    const chainIdRes = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1
    })

    const chainId = chainIdRes.data.result

    // Encode the message to set Contract to EOA 
    const authRLPEncode = RLP.encode([
        hexToBytes(chainId),
        setLengthLeft(hexToBytes(helloWorld), 20),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes(nonceTxSigner))), 
    ])

    // keccak256 hash of the rlp encoded message auth

    const keccak256HashAuth = keccak256(concatBytes(hexToBytes('0x05'), authRLPEncode))

    // sign the RLP auth transaction envelope output
    const signedMessageAuth = secp256k1.sign(keccak256HashAuth, txSignerPrivateKey,{extraEntropy:true})

    const gasLimitRes = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_estimateGas", "params": [{
            from: executorAddress,
            to: executorAddress,
            authorization_list: [[
                hexToBytes(chainId),
                setLengthLeft(hexToBytes(helloWorld), 20),
                hexToBytes(nonceTxSigner),                
                bigIntToUnpaddedBytes(BigInt(signedMessageAuth.recovery)),
                bigIntToUnpaddedBytes(signedMessageAuth.r),
                bigIntToUnpaddedBytes(signedMessageAuth.s),
            ]],
            value: `0x0`,
            type: "0x04"
        }], "id": 1
    })

    // const gasLimit = gasLimitRes.data.result
    const gasLimit = 0x327680 // 50000

    // chainId
    // nonce
    // max_prio
    // max_fee
    // gaslimit
    // destination
    // amount
    // data
    // access_list
    // authorization list
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
        toBytes(txSignerAddress),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes("0x0"))),
        toBytes("0xcfae3217"),
        [],
        [[
            hexToBytes(chainId),
            setLengthLeft(hexToBytes(helloWorld), 20),
            bigIntToUnpaddedBytes(bytesToBigInt(toBytes(nonceTxSigner))),
            bigIntToUnpaddedBytes(BigInt(signedMessageAuth.recovery)),
            bigIntToUnpaddedBytes(signedMessageAuth.r),
            bigIntToUnpaddedBytes(signedMessageAuth.s),
        ]]
    ])

    // keccak256 hash of the rlp encoded message
    const keccak256Hash = keccak256(concatBytes(txTypeBytes(4), rlpEncode))

    // sign the RLP transaction envelope output
    const signedMessage = secp256k1.sign(keccak256Hash, executorPrivateKey, { extraEntropy: true })

    // rlp the transaction envelope aka serialization
    const rlpEncode1 = RLP.encode([
        bigIntToUnpaddedBytes(BigInt(chainId)),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes(nonce))),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes("0x1"))),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes(feeHistory.baseFeePerGas[1]))),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes(gasLimit))),
        toBytes(txSignerAddress),
        bigIntToUnpaddedBytes(bytesToBigInt(toBytes("0x0"))),
        toBytes("0xcfae3217"),
        [],
        [[
            hexToBytes(chainId),
            setLengthLeft(hexToBytes(helloWorld), 20),
            bigIntToUnpaddedBytes(bytesToBigInt(toBytes(nonceTxSigner))),
            bigIntToUnpaddedBytes(BigInt(signedMessageAuth.recovery)),
            bigIntToUnpaddedBytes(signedMessageAuth.r),
            bigIntToUnpaddedBytes(signedMessageAuth.s),
        ]],
        bytesToBigInt(toBytes(BigInt(signedMessage.recovery))),
        bytesToBigInt(toBytes(BigInt(signedMessage.r))),
        bytesToBigInt(toBytes(BigInt(signedMessage.s))),
    ])

    // broadcast transaction : eth_sendRawTransaction
    const txRes = await axios.post(rpcUrl, {
        "jsonrpc": "2.0", "method": "eth_sendRawTransaction", "params": [bytesToHex(concatBytes(txTypeBytes(4), rlpEncode1))], "id": 1
    })
    console.log(txRes)

    // get the transaction receipt : eth_getTransactionReceipt
    pollTransaction(txRes.data.result).then(console.log)
}

main()