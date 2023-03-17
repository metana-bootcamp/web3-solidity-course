# Fuzzing Ethereum smart contract using Foundry fuzz

 In this video, I will show how to run and customize Foundry/Forge to fuzz an Ethereum smart contract in Solidity. I will also mention what, in my opinion, is missing regarding Foundry fuzzing compare to Echidna.

#fuzzing #ethereum #solidity

- Author: Patrick Ventuzelo 
- Link: https://academy.fuzzinglabs.com/introduction-to-ethereum-security


## Foundry

Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.
link: https://github.com/foundry-rs/foundry

Install:
``` sh
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
```

Init project:
```sh
forge init counter                                                                                                                                                                                                                
Initializing /home/scop/Documents/projects/fuzzing_with_foundry/counter...
Installing forge-std in "/home/scop/Documents/projects/fuzzing_with_foundry/counter/lib/forge-std" (url: Some("https://github.com/foundry-rs/forge-std"), tag: None)
    Installed forge-std v1.3.0
    Initialized forge project.
```

Links:
- https://www.paradigm.xyz/2021/12/introducing-the-foundry-ethereum-development-toolbox
- https://github.com/foundry-rs/foundry
- https://book.getfoundry.sh/forge/fuzz-testing


## Simple (default) Counter contract

src/Counter.sol
``` js
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
```

test/Counter.sol:
```js
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}

```


## Foundry property based testing

All functions declared inside `test/Counter.sol` that start with "test" e.g. `testIncrement` and `testSetNumber`

``` js
    function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
```

Run test with foundry:
```sh
forge test

[⠊] Compiling...
[⠔] Compiling 19 files with 0.8.14
[⠑] Solc 0.8.14 finished in 1.39s
Compiler run successful

Running 2 tests for test/Counter.t.sol:CounterTest
[PASS] testIncrement() (gas: 28356)
[PASS] testSetNumber(uint256) (runs: 256, μ: 27098, ~: 28342)
Test result: ok. 2 passed; 0 failed; finished in 9.08ms
```


## Fuzzing with Foundry

```sh
forge test
# Yes it's the same command
```

Modify fuzzing options using foundry.toml config:
``` toml
[fuzz]
runs = 150000
seed = 1234
```

Forge cheatcodes (std-cheats):
```js
// If this condition is not met the fuzzer will count it as a rejection
vm.assume(counter.number() != 5);

// create an address
address alice = makeAddr("alice");

// allow writing logs
string memory path = "output.txt";
string memory line1 = "first line";
vm.writeLine(path, line1);

// gives balances to an address
deal(address(dai), alice, 10000e18);

// forge the value to be in bounds
b = bound(b, 100, 500)
```

link:
- https://book.getfoundry.sh/reference/config/testing#fuzz
- https://book.getfoundry.sh/reference/forge-std/std-cheats
- https://hackmd.io/@xx8i-6tERA6IXXxVfWGABg/BkDI2dTsi


## `Invariant testing` with Foundry ??

Invariant testing means stuff that should not change over time i.e. after sequences of calls to the contract


links:
- https://github.com/lucas-manuel/invariant-examples


## Echidna vs Foundry

links:
- https://fuzzinglabs.com/wp-content/uploads/2022/07/EthCC5_Fuzzinglabs_State_of_the_Art_of_Ethereum_Smart_Contract_Fuzzing_in_2022.pdf
- https://github.com/clabby/echidna-vs-forge
- https://twitter.com/PaulRBerg/status/1617449048608313349?t=VMCJ16zI4WwCOaCCI1A8BA&s=19


# Going deeper

Check my dedicated fuzzing trainings:

- Go Security Audit and Fuzzing: https://academy.fuzzinglabs.com/go-security-audit-and-fuzzing
- C/C++ WhiteBox Fuzzing training: https://academy.fuzzinglabs.com/c-whitebox-fuzzing
- Rust Security Audit and Fuzzing: https://academy.fuzzinglabs.com/rust-security-audit-and-fuzzing-training
- WebAssembly Reversing and Dynamic Analysis: https://academy.fuzzinglabs.com/wasm-security-reversing-dynamic-analysis

# Stay tuned

- Twitter: https://twitter.com/pat_ventuzelo
- Telegram: https://t.me/fuzzinglabs
- Youtube: https://www.youtube.com/channel/UCGD1Qt2jgnFRjrfAITGdNfQ

Check my other tutorials and courses here: https://academy.fuzzinglabs.com/
