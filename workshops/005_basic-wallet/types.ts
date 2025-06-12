import { equalsBytes } from "./utils"



export type PrefixedHexString = `0x${string}`

export type BigIntLike = bigint | PrefixedHexString | number | Uint8Array


export class Address {
    public readonly bytes: Uint8Array

    constructor(bytes: Uint8Array) {
        if (bytes.length !== 20) {
            throw new Error('Invalid address length')
        }
        this.bytes = bytes
    }

    /**
     * Is address equal to another.
     */
    equals(address: Address): boolean {
        return equalsBytes(this.bytes, address.bytes)
    }

    /**
     * Is address zero.
     */
    isZero(): boolean {
        return this.equals(new Address(new Uint8Array(20)))
    }

    /**
     * True if address is in the address range defined
     * by EIP-1352
     */
    isPrecompileOrSystemAddress(): boolean {
        const address = bytesToBigInt(this.bytes)
        const rangeMin = BIGINT_0
        const rangeMax = BigInt('0xffff')
        return address >= rangeMin && address <= rangeMax
    }

    /**
     * Returns hex encoding of address.
     */
    toString(): PrefixedHexString {
        return bytesToHex(this.bytes)
    }

    /**
     * Returns a new Uint8Array representation of address.
     */
    toBytes(): Uint8Array {
        return new Uint8Array(this.bytes)
    }
}

export type AddressLike = Address | Uint8Array | PrefixedHexString

export interface TransformableToBytes {
    toBytes?(): Uint8Array
}

export type BytesLike =
    | Uint8Array
    | number[]
    | number
    | bigint
    | TransformableToBytes
    | PrefixedHexString

export type LegacyTxData = {
    /**
     * The transaction's nonce.
     */
    nonce?: BigIntLike

    /**
     * The transaction's gas price.
     */
    gasPrice?: BigIntLike | null

    /**
     * The transaction's gas limit.
     */
    gasLimit?: BigIntLike

    /**
     * The transaction's the address is sent to.
     */
    to?: AddressLike | ''

    /**
     * The amount of Ether sent.
     */
    value?: BigIntLike

    /**
     * This will contain the data of the message or the init of a contract.
     */
    data?: BytesLike | ''

    /**
     * EC recovery ID.
     */
    v?: BigIntLike

    /**
     * EC signature parameter.
     */
    r?: BigIntLike

    /**
     * EC signature parameter.
     */
    s?: BigIntLike

    /**
     * The transaction type
     */

    type?: BigIntLike
}
