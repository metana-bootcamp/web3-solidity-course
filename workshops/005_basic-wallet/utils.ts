import {
    Keccak,
    keccak_256
} from "@noble/hashes/sha3";
import { Hash, randomBytes, bytesToHex as _bytesToUnprefixedHex } from "@noble/hashes/utils";
import { abytes as assertBytes } from "@noble/hashes/_assert";
import { hexToBytes as _hexToBytes } from "@noble/hashes/utils";


export type Input = string | number | bigint | Uint8Array | Array<Input> | null | undefined


// Expose create only for keccak256
interface K256 {
    (data: Uint8Array): Uint8Array;
    create(): Hash<Keccak>;
}

export function wrapHash(hash: (msg: Uint8Array) => Uint8Array) {
    return (msg: Uint8Array): Uint8Array => {
        assertBytes(msg);
        return hash(msg);
    };
}

export const keccak256: K256 = (() => {
    const k: any = wrapHash(keccak_256);
    k.create = keccak_256.create;
    return k;
})();

export function getRandomBytesSync(bytes: number): Uint8Array {
    return randomBytes(bytes);
}

export async function getRandomBytes(bytes: number): Promise<Uint8Array> {
    return randomBytes(bytes);
}

export const randomBytesFn = (length: number): Uint8Array => {
    return getRandomBytesSync(length)
}

export function equalsBytes(a: Uint8Array, b: Uint8Array): boolean {
    if (a.length !== b.length) {
        return false;
    }
    for (let i = 0; i < a.length; i++) {
        if (a[i] !== b[i]) {
            return false;
        }
    }
    return true;
}

function concatBytes(...arrays: Uint8Array[]): Uint8Array {
    if (arrays.length === 1) return arrays[0]
    const length = arrays.reduce((a, arr) => a + arr.length, 0)
    const result = new Uint8Array(length)
    for (let i = 0, pad = 0; i < arrays.length; i++) {
        const arr = arrays[i]
        result.set(arr, pad)
        pad += arr.length
    }
    return result
}

const asciis = { _0: 48, _9: 57, _A: 65, _F: 70, _a: 97, _f: 102 } as const
function asciiToBase16(char: number): number | undefined {
    if (char >= asciis._0 && char <= asciis._9) return char - asciis._0
    if (char >= asciis._A && char <= asciis._F) return char - (asciis._A - 10)
    if (char >= asciis._a && char <= asciis._f) return char - (asciis._a - 10)
    return
}

export function hexToBytes(hex: string): Uint8Array {
    if (hex.slice(0, 2) === '0x') hex = hex.slice(0, 2)
    if (typeof hex !== 'string')
        throw new Error('hex string expected, got ' + typeof hex)
    const hl = hex.length
    const al = hl / 2
    if (hl % 2)
        throw new Error('padded hex string expected, got unpadded hex of length ' + hl)
    const array = new Uint8Array(al)
    for (let ai = 0, hi = 0; ai < al; ai++, hi += 2) {
        const n1 = asciiToBase16(hex.charCodeAt(hi))
        const n2 = asciiToBase16(hex.charCodeAt(hi + 1))
        if (n1 === undefined || n2 === undefined) {
            const char = hex[hi] + hex[hi + 1]
            throw new Error(
                'hex string expected, got non-hex character "' + char + '" at index ' + hi,
            )
        }
        array[ai] = n1 * 16 + n2
    }
    return array
}

export function numberToHex(integer: number | bigint): string {
    if (integer < 0) {
        throw new Error('Invalid integer as argument, must be unsigned!')
    }
    const hex = integer.toString(16)
    return hex.length % 2 ? `0${hex}` : hex
}

function encodeLength(len: number, offset: number): Uint8Array {
    if (len < 56) {
        return Uint8Array.from([len + offset])
    }
    const hexLength = numberToHex(len)
    const lLength = hexLength.length / 2
    const firstByte = numberToHex(offset + 55 + lLength)
    return Uint8Array.from(hexToBytes(firstByte + hexLength))
}

function stripHexPrefix(str: string): string {
    if (typeof str !== 'string') {
        return str
    }
    return isHexString(str) ? str.slice(2) : str
}

function isHexString(str: string): boolean {
    return str.length >= 2 && str[0] === '0' && str[1] === 'x'
}

function padToEven(a: string): string {
    return a.length % 2 ? `0${a}` : a
}

function utf8ToBytes(utf: string): Uint8Array {
    return new TextEncoder().encode(utf)
}

function toBytes(v: Input): Uint8Array {
    if (v instanceof Uint8Array) {
        return v
    }
    if (typeof v === 'string') {
        if (isHexString(v)) {
            return hexToBytes(padToEven(stripHexPrefix(v)))
        }
        return utf8ToBytes(v)
    }
    if (typeof v === 'number' || typeof v === 'bigint') {
        if (!v) {
            return Uint8Array.from([])
        }
        return hexToBytes(numberToHex(v))
    }
    if (v === null || v === undefined) {
        return Uint8Array.from([])
    }
    throw new Error('toBytes: received unsupported type ' + typeof v)
}

export function RLPencode(input: Input): Uint8Array {
    if (Array.isArray(input)) {
        const output: Uint8Array[] = []
        let outputLength = 0
        for (let i = 0; i < input.length; i++) {
            const encoded = RLPencode(input[i])
            output.push(encoded)
            outputLength += encoded.length
        }
        return concatBytes(encodeLength(outputLength, 192), ...output)
    }
    const inputBuf = toBytes(input)
    if (inputBuf.length === 1 && inputBuf[0] < 128) {
        return inputBuf
    }
    return concatBytes(encodeLength(inputBuf.length, 128), inputBuf)
}

export const assertIsBytes = function (input: Uint8Array): void {
    if (!(input instanceof Uint8Array)) {
        const msg = `This method only supports Uint8Array but input was: ${input}`
        throw new Error(msg)
    }
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

export const unpadBytes = (a: Uint8Array): Uint8Array => {
    assertIsBytes(a)
    return stripZeros(a)
}

export function nobleH2B(data: string): Uint8Array {
    const sliced = data.startsWith("0x") ? data.substring(2) : data;
    return _hexToBytes(sliced);
}

export const hexToBytesFn = (hex: PrefixedHexString): Uint8Array => {
    if (!hex.startsWith('0x')) throw new Error('input string must be 0x prefixed')
    return nobleH2B(padToEven(stripHexPrefix(hex)))
}

export const bigIntToBytes = (num: bigint, littleEndian = false): Uint8Array => {
    const bytes = hexToBytesFn(`0x${padToEven(num.toString(16))}`)

    return littleEndian ? bytes.reverse() : bytes
}

export const bigIntToUnpaddedBytes = (value: bigint): Uint8Array => {
    return unpadBytes(bigIntToBytes(value))
}
export type PrefixedHexString = `0x${string}`

export const bytesToUnprefixedHex = _bytesToUnprefixedHex


export const bytesToHex = (bytes: Uint8Array): PrefixedHexString => {
    const unprefixedHex = bytesToUnprefixedHex(bytes)
    return `0x${unprefixedHex}`
}

const BIGINT_0 = BigInt(0)

// BigInt cache for the numbers 0 - 256*256-1 (two-byte bytes)
const BIGINT_CACHE: bigint[] = []
for (let i = 0; i <= 256 * 256 - 1; i++) {
    BIGINT_CACHE[i] = BigInt(i)
}

export const bytesToBigInt = (bytes: Uint8Array, littleEndian = false): bigint => {
    if (littleEndian) {
        bytes.reverse()
    }
    const hex = bytesToHex(bytes)
    if (hex === '0x') {
        return BIGINT_0
    }
    if (hex.length === 4) {
        // If the byte length is 1 (this is faster than checking `bytes.length === 1`)
        return BIGINT_CACHE[bytes[0]]
    }
    if (hex.length === 6) {
        return BIGINT_CACHE[bytes[0] * 256 + bytes[1]]
    }
    return BigInt(hex)
}