# Race Condition

## Contract.sol

```js
interface ERC20 {
    function totalSupply() external  returns (uint);
    function balanceOf(address _owner) external  returns (uint);
    function transfer(address _to, uint _value) external  returns (bool);
    function transferFrom(address _from, address _to, uint _value) external  returns (bool);
    function approve(address _spender, uint _value) external  returns (bool);
    function allowance(address _owner, address _spender) external  returns (uint);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract RaceCondition{
    address private owner;
    uint public price;
    ERC20 token;

    constructor(uint _price, ERC20 _token)
        public 
    {
        owner = msg.sender;
        price = _price;
        token = _token;
    }

    // If the owner sees someone calls buy
    // he can call changePrice to set a new price
    // If his transaction is mined first, he can
    // receive more tokens than excepted by the new buyer
    function buy(uint new_price) payable
        public
    {
        require(msg.value >= price);

        // we assume that the RaceCondition contract
        // has enough allowance
        token.transferFrom(msg.sender, owner, price);

        price = new_price;
        owner = msg.sender;
    }

    function changePrice(uint new_price) public{
        require(msg.sender == owner);
        price = new_price; 
    }

}
```
# Race Condition
There is a gap between the creation of a transaction and the moment it is accepted in the blockchain.
Therefore, an attacker can take advantage of this gap to put a contract in a state that advantages them.

## Attack Scenario

- Bob creates `RaceCondition(100, token)`. Alice trusts `RaceCondition` with all its tokens. Alice calls `buy(150)`
Bob sees the transaction, and calls `changePrice(300)`. The transaction of Bob is mined before the one of Alice and
as a result, Bob received 300 tokens.

- The ERC20 standard's `approve` and `transferFrom` functions are vulnerable to a race condition. Suppose Alice has
approved Bob to spend 100 tokens on her behalf. She then decides to only approve him for 50 tokens and sends
a second `approve` transaction. However, Bob sees that he's about to be downgraded and quickly submits a
`transferFrom` for the original 100 tokens he was approved for. If this transaction gets mined before Alice's
second `approve`, Bob will be able to spend 150 of Alice's tokens.

## Mitigations

- For the ERC20 bug, insist that Alice only be able to `approve` Bob when he is approved for 0 tokens.
- Keep in mind that all transactions may be front-run
