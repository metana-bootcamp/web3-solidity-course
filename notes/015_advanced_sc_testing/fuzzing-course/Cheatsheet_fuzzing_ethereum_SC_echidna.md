# Fuzzing Ethereum smart contract using echidna

In this video, I will show how to find vulnerability inside an Ethereum smart contract written in Solidity using echidna, one of the only Ethereum smart contract fuzzer.

- Author: Patrick Ventuzelo 
- Link: https://academy.fuzzinglabs.com/introduction-to-ethereum-security

## Echidna

Ethereum smart contract fuzzer

Install:
``` sh
pip3 install slither-analyzer --user
git clone --depth 1 https://github.com/crytic/echidna

# download compiled Echidna
curl -fL https://github.com/crytic/echidna/releases/download/v1.7.3/echidna-test-1.7.3-Ubuntu-18.04.tar.gz -o echidna-test-1.7.3-Ubuntu-18.04.tar.gz
tar xvf echidna-test-1.7.3-Ubuntu-18.04.tar.gz
```

Links:
- https://github.com/crytic/echidna
- https://medium.com/coinmonks/smart-contract-fuzzing-d9b88e0b0a05

## Testing Echidna

``` sh
./echidna-test echidna/examples/solidity/exercises/testme.sol

Analyzing contract: /home/scop/Documents/projects/fuzzing_ethereum_smart_contract/echidna/examples/solidity/exercises/testme.sol:Canal
echidna_bothdown: fuzzing (15521/50000)
echidna_can_lower_second: failed!💥  
  Call sequence:
    raise(true)
    lower(false)


Unique instructions: 268
Unique codehashes: 1
Corpus size: 3
Seed: 3568399309931557071
```

## Echidna invariants

Start with `echidna_`:
``` js
  function echidna_bothdown() returns (bool) {
    return(first_gate_up || second_gate_up);
  }

  function echidna_can_lower_second() returns (bool) {
    bool a0 = lower(true);
    raise(true);
    return(a0);
  }
```

## Example: Missing.sol

``` js
pragma solidity ^0.4.15;

contract Missing{
    address private owner = 0x41414141;

    modifier onlyowner {
        require(msg.sender==owner);
        _;
    }

    // The name of the constructor should be Missing
    // Anyone can call the IamMissing once the contract is deployed
    function IamMissing()
        public 
    {
        owner = msg.sender;
    }

    function withdraw() 
        public 
        onlyowner
    {
       owner.transfer(this.balance);
    }

    function echidna_changeowner() returns (bool) {
        return owner == address(0x41414141);
    }
}
```

link: https://github.com/crytic/not-so-smart-contracts/blob/master/wrong_constructor_name/incorrect_constructor.sol

## Fuzzing Missing.sol with Echidna 

``` sh
./echidna-test Missing.sol
Analyzing contract: /home/scop/Documents/projects/fuzzing_ethereum_smart_contract/Missing.sol:Missing
echidna_changeowner: failed!💥  
  Call sequence:
    IamMissing()


Unique instructions: 155
Unique codehashes: 2
Corpus size: 1
Seed: -5341383664083542505
```

It's possible to provide configuration file: 
``` sh
./echidna-test Missing.sol --config config.yaml
```

config.yaml
``` sh
seqLen: 50
testLimit: 2000
prefix: "echidna_"
deployer: "0x41414141"
sender: ["0x42424242", "0x43434343"]
coverage: true
checkAsserts: true
```

## Issue with solc compiler version

You got this error:
``` sh
./echidna-test echidna/examples/solidity/exercises/testme.sol

echidna-test: Couldn't compile given file
stdout:
stderr:
ERROR:CryticCompile:Invalid solc compilation Error: Source file requires different compiler version (current compiler is 0.8.1+commit.df193b15.Linux.g++) - note that nightly builds are considered to be strictly less than the released version
 --> echidna/examples/solidity/exercises/testme.sol:1:1:
  |
1 | pragma solidity ^0.4.16;
```

Change solidity compiler version
``` sh
$ sudo curl -o /usr/bin/solc -fL https://github.com/ethereum/solidity/releases/download/v0.4.16/solc-static-linux
$ sudo chmod u+x /usr/bin/solc
$ solc --version
  solc, the solidity compiler commandline interface
  Version: 0.4.16+commit.d7661dd9.Linux.g++
```

# Stay tuned

- Twitter: https://twitter.com/pat_ventuzelo
- Telegram: https://t.me/fuzzinglabs
- Youtube: https://www.youtube.com/channel/UCGD1Qt2jgnFRjrfAITGdNfQ

Check my other tutorials and courses here: https://academy.fuzzinglabs.com/
