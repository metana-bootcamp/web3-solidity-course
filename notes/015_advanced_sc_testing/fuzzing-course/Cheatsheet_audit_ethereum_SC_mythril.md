# Solidity audit & Ethereum Smart Contract analysis using Mythril

Following last week's video, I will show how to audit and find vulnerability inside an Ethereum smart contract written in Solidity using Mythril, one of the best EVM smart contract analysis tools.

- Author: Patrick Ventuzelo 
- Link: https://academy.fuzzinglabs.com/introduction-to-ethereum-security


# Our target contract: `etherstore.sol`

link: https://github.com/sigp/solidity-security-blog#1-re-entrancy-1

``` js
contract EtherStore {

    uint256 public withdrawalLimit = 1 ether;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public balances;

    function depositFunds() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdrawFunds (uint256 _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw);
        // limit the withdrawal
        require(_weiToWithdraw <= withdrawalLimit);
        // limit the time allowed to withdraw
        require(now >= lastWithdrawTime[msg.sender] + 1 weeks);
        require(msg.sender.call.value(_weiToWithdraw)());
        balances[msg.sender] -= _weiToWithdraw;
        lastWithdrawTime[msg.sender] = now;
    }
}
```

# Mythril

Github: https://github.com/ConsenSys/mythril
Docs: https://mythril-classic.readthedocs.io/en/master/index.html

Install:
``` sh
pip3 install mythril
```

Commands:
``` sh
$ myth help

usage: myth [-h] [-v LOG_LEVEL]
            {safe-functions,analyze,a,disassemble,d,list-detectors,read-storage,function-to-hash,hash-to-address,version,help} ...

Security analysis of Ethereum smart contracts

positional arguments:
  {safe-functions,analyze,a,disassemble,d,list-detectors,read-storage,function-to-hash,hash-to-address,version,help}
                        Commands
    safe-functions      Check functions which are completely safe using symbolic execution
    analyze (a)         Triggers the analysis of the smart contract
    disassemble (d)     Disassembles the smart contract
    list-detectors      Lists available detection modules
    read-storage        Retrieves storage slots from a given address through rpc
    function-to-hash    Returns the hash signature of the function
    hash-to-address     converts the hashes in the blockchain to ethereum address
    version             Outputs the version

optional arguments:
  -h, --help            show this help message and exit
  -v LOG_LEVEL          log level (0-5)

```

# Running Mythril on `etherstore.sol`

``` sh
$ myth analyze etherstore.sol

==== Integer Arithmetic Bugs ====
SWC ID: 101
Severity: High
Contract: EtherStore
Function name: withdrawFunds(uint256)
PC address: 534
Estimated Gas Usage: 14650 - 89691
The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation. 
--------------------
In file: reentrancy.sol:16

lastWithdrawTime[msg.sender] + 1 weeks

--------------------
Initial State:

Account: [CREATOR], balance: 0x21c10c00020fbfbd, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x2, nonce:0, storage:{}
Account: [SOMEGUY], balance: 0x0, nonce:0, storage:{}

Transaction Sequence:

Caller: [CREATOR], calldata: , value: 0x0
Caller: [SOMEGUY], function: withdrawFunds(uint256), txdata: 0x155dd5ee, value: 0x0
Caller: [SOMEGUY], function: withdrawFunds(uint256), txdata: 0x155dd5ee, value: 0x0

==== Dependence on predictable environment variable ====
SWC ID: 116
Severity: Low
Contract: EtherStore
Function name: withdrawFunds(uint256)
PC address: 543
Estimated Gas Usage: 2822 - 3297
A control flow decision is made based on The block.timestamp environment variable.
The block.timestamp environment variable is used to determine a control flow decision. Note that the values of variables like coinbase, gaslimit, block number and timestamp are predictable and can be manipulated by a malicious miner. Also keep in mind that attackers know hashes of earlier blocks. Don\'t use any of those environment variables as sources of randomness and be aware that use of these variables introduces a certain level of trust into miners.
--------------------
In file: reentrancy.sol:16

require(now >= lastWithdrawTime[msg.sender] + 1 weeks)

--------------------
Initial State:

Account: [CREATOR], balance: 0x2009cfdd, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x200, nonce:0, storage:{}
Account: [SOMEGUY], balance: 0x0, nonce:0, storage:{}

Transaction Sequence:

Caller: [CREATOR], calldata: , value: 0x0
Caller: [ATTACKER], function: withdrawFunds(uint256), txdata: 0x155dd5ee, value: 0x0

==== External Call To User-Supplied Address ====
SWC ID: 107
Severity: Low
Contract: EtherStore
Function name: withdrawFunds(uint256)
PC address: 592
Estimated Gas Usage: 14650 - 89691
A call to a user-supplied address is executed.
An external message call to an address specified by the caller is executed. Note that the callee account might contain arbitrary code and could re-enter any function within this contract. Reentering the contract in an intermediate state may lead to unexpected behaviour. Make sure that no state modifications are executed after this call and/or reentrancy guards are in place.
--------------------
In file: reentrancy.sol:17

msg.sender.call.value(_weiToWithdraw)()

--------------------
Initial State:

Account: [CREATOR], balance: 0x421c00c00020bfffb, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x4654d4000000003, nonce:0, storage:{}
Account: [SOMEGUY], balance: 0x0, nonce:0, storage:{}

Transaction Sequence:

Caller: [CREATOR], calldata: , value: 0x0
Caller: [ATTACKER], function: withdrawFunds(uint256), txdata: 0x155dd5ee, value: 0x0
Caller: [ATTACKER], function: withdrawFunds(uint256), txdata: 0x155dd5ee, value: 0x0

==== State access after external call ====
SWC ID: 107
Severity: Medium
Contract: EtherStore
Function name: withdrawFunds(uint256)
PC address: 676
Estimated Gas Usage: 14650 - 89691
Read of persistent state following external call
The contract account state is accessed after an external call to a user defined address. To prevent reentrancy issues, consider accessing the state only before the call, especially if the callee is untrusted. Alternatively, a reentrancy lock can be used to prevent untrusted callees from re-entering the contract in an intermediate state.
--------------------
In file: reentrancy.sol:18

balances[msg.sender] -= _weiToWithdraw

--------------------
Initial State:

Account: [CREATOR], balance: 0x1000000000778df, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x2, nonce:0, storage:{}
Account: [SOMEGUY], balance: 0x0, nonce:0, storage:{}

Transaction Sequence:

Caller: [CREATOR], calldata: , value: 0x0
Caller: [ATTACKER], function: withdrawFunds(uint256), txdata: 0x155dd5ee, value: 0x0

==== State access after external call ====
SWC ID: 107
Severity: Medium
Contract: EtherStore
Function name: withdrawFunds(uint256)
PC address: 683
Estimated Gas Usage: 14650 - 89691
Write to persistent state following external call
The contract account state is accessed after an external call to a user defined address. To prevent reentrancy issues, consider accessing the state only before the call, especially if the callee is untrusted. Alternatively, a reentrancy lock can be used to prevent untrusted callees from re-entering the contract in an intermediate state.
--------------------
In file: reentrancy.sol:18

balances[msg.sender] -= _weiToWithdraw

--------------------
Initial State:

Account: [CREATOR], balance: 0x1000000000778df, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x2, nonce:0, storage:{}
Account: [SOMEGUY], balance: 0x0, nonce:0, storage:{}

Transaction Sequence:

Caller: [CREATOR], calldata: , value: 0x0
Caller: [ATTACKER], function: withdrawFunds(uint256), txdata: 0x155dd5ee, value: 0x0

==== State access after external call ====
SWC ID: 107
Severity: Medium
Contract: EtherStore
Function name: withdrawFunds(uint256)
PC address: 751
Estimated Gas Usage: 14650 - 89691
Write to persistent state following external call
The contract account state is accessed after an external call to a user defined address. To prevent reentrancy issues, consider accessing the state only before the call, especially if the callee is untrusted. Alternatively, a reentrancy lock can be used to prevent untrusted callees from re-entering the contract in an intermediate state.
--------------------
In file: reentrancy.sol:19

lastWithdrawTime[msg.sender] = now

--------------------
Initial State:

Account: [CREATOR], balance: 0x1000000000778df, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x2, nonce:0, storage:{}
Account: [SOMEGUY], balance: 0x0, nonce:0, storage:{}

Transaction Sequence:

Caller: [CREATOR], calldata: , value: 0x0
Caller: [ATTACKER], function: withdrawFunds(uint256), txdata: 0x155dd5ee, value: 0x0
```

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