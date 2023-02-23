```shell
# install
curl -L https://foundry.paradigm.xyz | bash
foundryup

forge install

FORK_URL=https://eth-mainnet.g.alchemy.com/v2/613t3mfjTevdrCwDl28CVvuk6wSIxRPi
forge test -vvvv --fork-url $FORK_URL
```

#### Original Credits
* [stakewithus/defi-by-example](https://github.com/stakewithus/defi-by-example/tree/main/read-only-reentrancy)
* [Curve ETH/stETH stableSwap Contract](https://github.com/curvefi/curve-contract/blob/master/contracts/pools/steth/StableSwapSTETH.vy)