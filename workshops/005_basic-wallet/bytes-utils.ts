import { hexToBytes as _hexToBytes, bytesToHex as _bytesToUnprefixedHex } from "@noble/hashes/utils";

export interface TransformableToBytes {
    toBytes?(): Uint8Array
}

export type ToBytesInputTypes =
    | PrefixedHexString
    | number
    | bigint
    | Uint8Array
    | number[]
    | TransformableToBytes
    | null
    | undefined

export type PrefixedHexString = `0x${string}`

export const stripHexPrefix = (str: string): string => {
    if (typeof str !== 'string')
        throw new Error(
            `[stripHexPrefix] input must be type 'string', received ${typeof str}`,
        )

    return isHexString(str) ? str.slice(2) : str
}

export const hexToBytes = (hex: PrefixedHexString): Uint8Array => {
    if (!hex.startsWith('0x')) throw new Error('input string must be 0x prefixed')
    return nobleH2B(padToEven(stripHexPrefix(hex)))
}

export function isHexString(value: string, length?: number): value is PrefixedHexString {
    if (typeof value !== 'string' || !value.match(/^0x[0-9A-Fa-f]*$/)) return false

    if (typeof length !== 'undefined' && length > 0 && value.length !== 2 + 2 * length) return false

    return true
}

export const intToHex = (i: number): PrefixedHexString => {
    if (!Number.isSafeInteger(i) || i < 0) {
        throw new Error(`Received an invalid integer type: ${i}`)
    }
    return `0x${i.toString(16)}`
}

const stripZeros = <T extends Uint8Array | number[] | string = Uint8Array | number[] | string>(
    a: T,
): T => {
    let first = a[0]
    while (a.length > 0 && first.toString() === '0') {
        a = a.slice(1) as T
        first = a[0]
    }
    return a
}

export const assertIsBytes = function (input: Uint8Array): void {
    if (!(input instanceof Uint8Array)) {
        const msg = `This method only supports Uint8Array but input was: ${input}`
        throw new Error(msg)
    }
}

export const unpadBytes = (a: Uint8Array): Uint8Array => {
    assertIsBytes(a)
    return stripZeros(a)
}

export const intToBytes = (i: number): Uint8Array => {
    const hex = intToHex(i)
    return hexToBytes(hex)
}

const BIGINT_0 = BigInt(0)


export const toBytes = (v: ToBytesInputTypes): Uint8Array => {
    if (v === null || v === undefined) {
        return new Uint8Array()
    }

    if (Array.isArray(v) || v instanceof Uint8Array) {
        return Uint8Array.from(v)
    }

    if (typeof v === 'string') {
        if (!isHexString(v)) {
            throw new Error(
                `Cannot convert string to Uint8Array. toBytes only supports 0x-prefixed hex strings and this string was given: ${v}`,
            )
        }
        return hexToBytes(v)
    }

    if (typeof v === 'number') {
        return intToBytes(v)
    }

    if (typeof v === 'bigint') {
        if (v < BIGINT_0) {
            throw new Error(`Cannot convert negative bigint to Uint8Array. Given: ${v}`)
        }
        let n = v.toString(16)
        if (n.length % 2) n = '0' + n
        return unprefixedHexToBytes(n)
    }

    if (v.toBytes !== undefined) {
        // converts a `TransformableToBytes` object to a Uint8Array
        return v.toBytes()
    }

    throw new Error('invalid type')
}

export function padToEven(value: string): string {
    let a = value

    if (typeof a !== 'string') {
        throw new Error(
            `[padToEven] value must be type 'string', received ${typeof a}`,
        )
    }

    if (a.length % 2) a = `0${a}`

    return a
}

export function nobleH2B(data: string): Uint8Array {
    const sliced = data.startsWith("0x") ? data.substring(2) : data;
    return _hexToBytes(sliced);
}

export const unprefixedHexToBytes = (hex: string): Uint8Array => {
    if (hex.startsWith('0x')) throw new Error('input string cannot be 0x prefixed')
    return nobleH2B(padToEven(hex))
}