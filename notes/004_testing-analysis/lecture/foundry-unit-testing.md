## Unit testing in foundry

### Install foundry

* Follow the instructions here: https://book.getfoundry.sh/getting-started/installation

### Foundry hello world
* Just run the following commands and it will set up the environment, create tests, and run them for you. (This assumes you have Foundry installed of course).

```
$ forge init
$ forge test
```

### Foundry Asserts
* To ensure a state transition actually happened, you will need asserts.
* Open tests/Counter.t.sol
```
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

* the `setUp()` function deploys the contract you are testing (as well as any other contract you want in the ecosystem).
* Any function that starts with the word test will be executed as a unit test. Functions that do not start with “test” will not be executed unless a test or setUp function calls them.


The asserts used most frequently are:

* `assertEq`, assert equal
* `assertLt`, assert less than
* `assertLe`, assert less than or equal to
* `assertGt`, assert greater than
* `assertGe`, assert greater than or equal to
* `assertTrue`, assert to be true

* The first two arguments to the assert are the comparison, but you can also add a helpful error message as a third argument, which you should always do (despite the default example not showing it). Here is the suggested way of writing assertions:

```
function testIncrement() public {
        counter.increment();
        assertEq(counter.number(), 1, "expect x to equal to 1");
}

function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x, "x should be setNumber");
}
```

### Changing `msg.sender` with foundry's `vm.prank`
* Foundry’s rather humorous method to change the sender (account or wallet) is the `vm.prank` API (what foundry calls a cheatcode).

* Here is a minimal example

```
function testChangeOwner() public {
		vm.prank(owner);
    contractToTest.changeOwner(newOwner);
    assertEq(contractToTest.owner(), newOwner);
}
```

The `vm.prank` only works for the transaction that happens immediately after. If you want a sequence of transactions to use the same address, use `vm.startPrank` and end them `vm.stopPrank`

```
function testMultipleTransactions() public {
	vm.startPrank(owner);
	// behave as owner
	vm.stopPrank();
}
```

### Defining accounts and addresses in Foundry

* The `owner` variable above can be defined a few ways:

```
// an address created by casting a decimal to an address
address owner = address(1234);

// vitalik's addresss
address owner = 0x0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

// create an address from a known private key;
address owner = vm.addr(privateKey);

// create an attacker
address hacker = 0x00baddad
```

* `msg.sender` and `tx.origin` prank

* In the above examples, `msg.sender` is altered. If you specifically want control over both `tx.origin` and `msg.sender`, both `vm.prank` and `vm.startPrank` optionally take two arguments where the second argument is `tx.origin`.

```
vm.prank(msgSender, txOrigin);
```

> Relying on tx.origin is generally a bad practice, so you will rarely need to use the two-argument version of vm.prank.

### Checking balances

* When you transfer ether, you should measure that the balances changed as expected. Thankfully, checking balances in foundry is easy, since it is written in Solidity.

* Consider this contract

```
contract Deposit {

	event Deposited(address indexed);

	function buyerDeposit() external payable {
		require(msg.value == 1 ether, "incorrect amount");
		emit Deposited(msg.sender);
	}

	// rest of the logic
}
```

* The test function would look like this.

```
function testBuyerDeposit() public {
	uint256 balanceBefore = address(depositContract).balance;
	depositContract.buyerDeposit{value: 1 ether}();
	uint256 balanceAfter = address(depositContract).balance;

	assertEq(balanceAfter - balanceBefore, 1 ether, "expect increase of 1 ether");
}
```

> Note that we haven’t tested the cases where the buyer sent an amount other than 1 ether, which would cause a revert.

### Expecting reverts with `vm.expectRevert`

* The problem with the test above in its current form is that you could delete the require statement and the test would still pass. Let’s improve the test so that deleting the require statement causes a test to fail.

```
function testBuyerDepositWrongPrice() public {
	vm.expectRevert("incorrect amount");
	depositContract.deposit{value: 1 ether + 1 wei}();

	vm.expectRevert("incorrect amount");
	depositContract.deposit{value: 1 ether - 1 wei}();
}
```

> Note that `vm.expectRevert` must be called right before doing the function that we expect to revert. Now if we delete the `require` statement, it will `revert`, so we have better modeled the intended functionality of the smart contract.

### Testing Custom Errors

* If we use custom errors instead of require statements, the way to test the revert would be as follows

```
contract CustomErrorContract {
    error SomeError(uint256);

    function revertError(uint256 x) public pure {
        revert SomeError(x);
    }
}
```

* And the test file would be like this

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/RevertCustomError.sol";

contract CounterTest is Test {
    CustomErrorContract public customErrorContract;
    error SomeError(uint256);

    function setUp() public {
        customErrorContract = new CustomErrorContract();
    }

    function testRevert() public {
				// 5 is an arbitrary example
        vm.expectRevert(abi.encodeWithSelector(SomeError.selector, 5));
        customErrorContract.revertError(5);
    }
}
```

* In our example, we’ve created a parameterized custom error. For the test to pass, the parameter needs to be equal the one actually used during the revert.


### Testing logs and events with `vm.expectEvent`

* Although solidity events don’t alter the functionality of a smart contract, incorrectly implementing them can break client applications that read the state of a smart contract. To ensure our events function as expected, we can use the vm.expectEmit. This API behaves rather counterintuitively because you must emit the event in the test to ensure it worked in the smart contract.

* Here is a minimal example.

```
function testBuyerDepositEvent() public {
	vm.expectEmit();
  emit Deposited(buyer);

	depositContract.deposit{value: 1 ether}();
}
```

* Adjusting `block.timestamp` with `vm.warp`

* Now let’s consider a time locked withdrawal. The seller can withdraw the payment after 3 days.

```
contract Deposit {

	address public seller;
	mapping(address => uint256) public depositTime;

	event Deposited(address indexed);
	event SellerWithdraw(address indexed, uint256 indexed);

	constructor(address _seller) {
		seller = _seller;
	}

	function buyerDeposit() external payable {
		require(msg.value == 1 ether, "incorrect amount");
		uint256 _depositTime = depositTime[msg.sender];
		require(_depositTime == 0, "already deposited");
		depositTime[msg.sender] = block.timestamp;

		emit Deposited(msg.sender);
	}

	function sellerWithdraw(address buyer) external {
		require(msg.sender == seller, "not the seller");
		uint256 _depositTime = depositTime[buyer];
		require(_depositTime != 0, "buyer did not deposit");
		require(block.timestamp - _depositTime > 3 days, "refund period not passed");
		delete depositTime[buyer];

		emit SellerWithdraw(buyer, block.timestamp);
		(bool ok, ) = msg.sender.call{value: 1 ether}("");
		require(ok, "seller did not withdraw");
	}
}
```

* We’ve added a lot of functionality that needs to be tested, but let’s focus on the time aspect for now.

* We want to test that the seller cannot withdraw the money until 3 days since the deposit. (There is obviously a missing function for the buyer to withdraw before that window).


* There is a very big gotcha. The test starts at timestamp zero by default, not the current timestamp. So even if a buyer deposits, the seller cannot withdraw because the require statement for “buyer did not deposit” will cause the transaction to revert. Because of that, we want to warp to the present day first, or at least a time when the timestamp isn’t zero.


* This can be done with `vm.warp(x)`, but let’s be fancy and use a modifier.

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Deposit.sol";

contract DepositTest is Test {
    Deposit public deposit;
    Deposit public faildeposit;
    address constant SELLER = address(0x5E11E7);
    //address constant Rejector = address(RejectTransaction);
    RejectTransaction private rejector;

    event Deposited(address indexed);
    event SellerWithdraw(address indexed, uint256 indexed);

    function setUp() public {
        deposit = new Deposit(SELLER);
        rejector = new RejectTransaction();
        faildeposit = new Deposit(address(rejector));
    }

    modifier startAtPresentDay() {
        vm.warp(1680616584);
        _;
    }

    address public buyer = address(this); // the DepositTest contract is the "buyer"
    address public buyer2 = address(0x5E11E1); // random address
    address public FakeSELLER = address(0x5E1222); // random address

    function testDepositAmount() public startAtPresentDay {
        // this test checks that the buyer can only deposit 1 ether
        vm.startPrank(buyer);
        vm.expectRevert();
        deposit.buyerDeposit{value: 1.5 ether}();
        vm.expectRevert();
        deposit.buyerDeposit{value: 2.5 ether}();
        vm.stopPrank();
    }
}
```

### Adjusting `block.number` with `vm.roll`

* If you want to adjust the block number (`block.number`) in Foundry, use `vm.roll(blockNumber)` to change the block number.

### Adding the extra tests

* For the sake of completeness, let’s write the unit tests for the rest of the functions.
* Some additional features need to be tested for the deposit function:

 * the public variable depositTime matches the time of the transaction
 * a user cannot deposit twice
 * And for the seller function:
 * the seller cannot withdraw for non-existent addresses
 * the entry for the buyer is deleted (this allows the buyer to buy again)
 * the SellerWithdraw event is emitted
 * the contract’s balance is decreased by 1 ether
 * an address that is not the seller calling sellerWithdraw gets reverted

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Deposit.sol";

contract DepositTest is Test {
    Deposit public deposit;
    Deposit public faildeposit;
    address constant SELLER = address(0x5E11E7);
    //address constant Rejector = address(RejectTransaction);
    RejectTransaction private rejector;

    event Deposited(address indexed);
    event SellerWithdraw(address indexed, uint256 indexed);

    function setUp() public {
        deposit = new Deposit(SELLER);
        rejector = new RejectTransaction();
        faildeposit = new Deposit(address(rejector));
    }

    modifier startAtPresentDay() {
        vm.warp(1680616584);
        _;
    }

    address public buyer = address(this); // the DepositTest contract is the "buyer"
    address public buyer2 = address(0x5E11E1); // random address
    address public FakeSELLER = address(0x5E1222); // random address

    function testDepositAmount() public startAtPresentDay {
        // this test checks that the buyer can only deposit 1 ether
        vm.startPrank(buyer);
        vm.expectRevert();
        deposit.buyerDeposit{value: 1.5 ether}();
        vm.expectRevert();
        deposit.buyerDeposit{value: 2.5 ether}();
        vm.stopPrank();
    }

    function testBuyerDepositSellerWithdrawAfter3days() public startAtPresentDay {
        // This test checks that the seller is able to withdraw 3 days after the buyer deposits

        // buyer deposits 1 ether
        vm.startPrank(buyer); // msg.sender == buyer
        deposit.buyerDeposit{value: 1 ether}();
        assertEq(address(deposit).balance, 1 ether, "Contract balance did not increase"); // checks to see if the contract balance increases
        vm.stopPrank();

        // after three days the seller withdraws
        vm.startPrank(SELLER); // msg.sender == SELLER
        vm.warp(1680616584 + 3 days + 1 seconds);
        deposit.sellerWithdraw(address(this));
        assertEq(address(deposit).balance, 0 ether, "Contract balance did not decrease"); // checks to see if the contract balance decreases
    }

    function testBuyerDepositSellerWithdrawBefore3days() public startAtPresentDay {
        // This test checks that the seller is able to withdraw 3 days after the buyer deposits

        // buyer deposits 1 ether
        vm.startPrank(buyer); // msg.sender == buyer
        deposit.buyerDeposit{value: 1 ether}();
        assertEq(address(deposit).balance, 1 ether, "Contract balance did not increase"); // checks to see if the contract balance increases
        vm.stopPrank();

        // before three days the seller withdraws
        vm.startPrank(SELLER); // msg.sender == SELLER
        vm.warp(1680616584 + 2 days);
        vm.expectRevert(); // expects a revert
        deposit.sellerWithdraw(address(this));
    }

    function testdepositTimeMatchesTimeofTransaction() public startAtPresentDay {
        // This test checks that the public variable depositTime matches the time of the transaction

        vm.startPrank(buyer); // msg.sender == buyer
        deposit.buyerDeposit{value: 1 ether}();
        // check that it deposits at the right time
        assertEq(
            deposit.depositTime(buyer),
            1680616584, // time of startAtPresentDay
            "Time of Deposit Doesnt Match"
        );
        vm.stopPrank();
    }

    function testUserDepositTwice() public startAtPresentDay {
        // This test checks that a user cannot deposit twice 

        vm.startPrank(buyer); // msg.sender == buyer
        deposit.buyerDeposit{value: 1 ether}();

        vm.warp(1680616584 + 1 days); // one day later...
        vm.expectRevert();
        deposit.buyerDeposit{value: 1 ether}(); // should revert since it hasn't been 3 days
    }

    function testNonExistantContract() public startAtPresentDay {
        // This test checks that the seller cannot withdraw for non-existent addresses

        vm.startPrank(SELLER); // msg.sender == SELLER
        vm.expectRevert();
        deposit.sellerWithdraw(buyer); 
    }

    function testBuyerBuysAgain() public startAtPresentDay {
        // This test checks that the entry for the buyer is deleted (this allows the buyer to buy again)

        vm.startPrank(buyer); // msg.sender == buyer
        deposit.buyerDeposit{value: 1 ether}();
        vm.stopPrank();

        // seller withdraws
        vm.warp(1680616584 + 3 days + 1 seconds);
        vm.startPrank(SELLER); // msg.sender == SELLER
        deposit.sellerWithdraw(buyer);
        vm.stopPrank();

        // checks depostitime[buyer] == 0
        assertEq(deposit.depositTime(buyer), 0, "entry for buyer is not deleted");

        // buyer deposits again
        vm.startPrank(buyer); // msg.sender == buyer
        vm.expectEmit();
        emit Deposited(buyer);
        deposit.buyerDeposit{value: 1 ether}();
        vm.stopPrank();
    }

    function testSellerWithdrawEmitted() public startAtPresentDay {
        // this test checks that the SellerWithdraw event is emitted

        //buyer2 deposits
        vm.deal(buyer2, 1 ether); // msg.sender == buyer2
        vm.startPrank(buyer2);
        vm.expectEmit(); // Deposited Emitter checked
        emit Deposited(buyer2);
        deposit.buyerDeposit{value: 1 ether}();
        vm.stopPrank();

        vm.warp(1680616584 + 3 days + 1 seconds);// 3 day and 1 second later...

        // seller withdraws + checks SellerWithdraw event emmited or not
        vm.startPrank(SELLER); // msg.sender == SELLER
        vm.expectEmit(); // expects SellerWithdraw Emitterd
        emit SellerWithdraw(buyer2, block.timestamp);
        deposit.sellerWithdraw(buyer2);
        vm.stopPrank();
    }

		function testFakeSeller2Withdraw() public startAtPresentDay {
        // buyer deposits
        vm.startPrank(buyer);
        vm.deal(buyer, 2 ether); // this contract's address is the buyer
        deposit.buyerDeposit{value: 1 ether}();
        vm.stopPrank();
        assertEq(address(deposit).balance, 1 ether, "Ether deposited somehow failed");

        vm.warp(1680616584 + 3 days + 1 seconds); // 3 day and 1 second later...

        vm.startPrank(FakeSELLER); // msg.sender == FakeSELLER
        vm.expectRevert();
        deposit.sellerWithdraw(buyer);
        vm.stopPrank();
    }

    function testRejectedWithdrawl() public startAtPresentDay {
        // This test checks that the entry for the buyer is deleted (this allows the buyer to buy again)
        
				vm.startPrank(buyer); // msg.sender == buyer
        faildeposit.buyerDeposit{value: 1 ether}();
        vm.stopPrank();
        assertEq(address(faildeposit).balance, 1 ether, "assertion failed");

        vm.warp(1680616584 + 3 days + 1 seconds); // 3 days and 1 second later...
        
        vm.startPrank(address(rejector)); // msg.sender == rejector
        vm.expectRevert();
        faildeposit.sellerWithdraw(buyer);
        vm.stopPrank();
    }
}
```

### Testing failed ether transfers

* Testing the buyer withdraw requires an extra trick to get full line coverage. Here is the snippet we are testing, and we will explain the Rejector contract in the code above.

```
function buyerWithdraw() external {
	uint256 _depositTime = depositTime[msg.sender];
	require(_depositTime != 0, "sender did not deposit");
	require(block.timestamp - _depositTime <= 3 days);

	emit BuyerRefunded(msg.sender, block.timestamp);

	// this is the branch we are testing
	(bool ok,) = msg.sender.call{value: 1 ether}("");
	require(ok, "Failed to withdraw");
}
```

* To test the fail condition of “require(ok…)” we need the Ether transfer to fail. The way the test accomplishes this is by creating a smart contract that calls the buyerWithdraw function, but has its receive function set to revert.


### Foundry Fuzzing
* Although we can specify an arbitrary address that isn’t the seller to test the revert of an unauthorized address withdrawing, it’s more mentally reassuring to try a lot of different values.
* If we supply an argument to the test functions, foundry will try a bunch of different values for the arguments. To prevent it from using arguments that don’t apply to the test case (such as when the address is authorized), we would use vm.assume. Here’s how we can test the seller withdraw for an unauthorized seller.

```
// notSeller will be chosen randomly
function testInvalidSellerAddress(address notSeller) public {
	vm.assume(notSeller != seller);

	vm.expectRevert("not the seller");
	depositContract.sellerWithdraw(notSeller);
}
```

* Here are all the state transitions
 * The contract’s balance decreases by 1 ether
 * The BuyerRefunded event was emitted
 * The buyer can refund before three days
 * Here are the branches that need to be tested
 * the buyer cannot withdraw after 3 days
 * The buyer cannot withdraw if they never deposited


### Testing signatures
Refer [solidity signature verification with foundry](../../011_scaling_blockchain/lecture/foundry-signature-verification.md).


### Setting address balances with `vm.deal` and `vm.hoax`

* The cheat code `vm.hoax` allows you to prank an address and set it’s balance simultaneously.

```
vm.hoax(addressToPrank, balanceToGive);
// next call is a prank for addressToPrank

vm.deal(alice, balanceToGive);
```

### Take aways
* aim for 100% line and branch coverage
* fully define the expected state transitions
* use error messages in your asserts

### Source

* [Foundry Unit Tests](https://www.rareskills.io/post/foundry-testing-solidity)