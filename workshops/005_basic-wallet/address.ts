export class Address {
    public readonly bytes: Uint8Array
  
    constructor(bytes: Uint8Array) {
      if (bytes.length !== 20) {
        throw EthereumJSErrorWithoutCode('Invalid address length')
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