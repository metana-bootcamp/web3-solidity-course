```shell
# install
curl -L https://foundry.paradigm.xyz | bash
foundryup

forge install

FORK_URL=https://eth-mainnet.g.alchemy.com/v2/613t3mfjTevdrCwDl28CVvuk6wSIxRPi
forge test -vvvv --fork-url $FORK_URL
```

Contracts

* [Curve ETH/stETH StableSwap](https://etherscan.io/address/0xDC24316b9AE028F1497c275EB9192a3Ea0f67022#code)
* [steCRV](https://etherscan.io/address/0x06325440d014e39736583c165c2963ba99faf14e#code)
* [steCRV Gauge Deposit](https://etherscan.io/address/0x182b723a58739a9c974cfdb385ceadb237453c28#code)

#### Original Credits
* [stakewithus/defi-by-example](https://github.com/stakewithus/defi-by-example/tree/main/read-only-reentrancy)
* [Curve ETH/stETH stableSwap Contract](https://github.com/curvefi/curve-contract/blob/master/contracts/pools/steth/StableSwapSTETH.vy)