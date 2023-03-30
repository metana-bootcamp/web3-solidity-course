pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestDai is ERC20("Dai Stablecoin", "Dai") {
  mapping (address => uint) public nonces;

  bytes32 public DOMAIN_SEPARATOR;
  // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
  bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

  constructor() public {
    _mint(0xDa1d30af457b8386083C66c9Df7A86269bEbFDF8, 100 ether);

    DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("Dai Stablecoin")),
            keccak256(bytes("1")),
            chainId(),
            address(this)
        ));
  }

  function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                  bool allowed, uint8 v, bytes32 r, bytes32 s) external
  {
    bytes32 digest =
      keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PERMIT_TYPEHASH,
                             holder,
                             spender,
                             nonce,
                             expiry,
                             allowed))
    ));

    require(holder != address(0), "Dai/invalid-address-0");
    require(holder == ecrecover(digest, v, r, s), "Dai/invalid-permit");
    require(expiry == 0 || block.timestamp <= expiry, "Dai/permit-expired");
    require(nonce == nonces[holder]++, "Dai/invalid-nonce");
    uint wad = allowed ? uint(-1) : 0;

    console.log("approve:",holder,spender,wad);
    _approve(holder, spender, wad);
  }

  function chainId() private pure returns (uint _chainId) {
    assembly {
      _chainId := chainid()
    }
  }
}

