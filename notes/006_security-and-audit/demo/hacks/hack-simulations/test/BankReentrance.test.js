const {assert} = require("chai");
const { ethers } = require("hardhat");

describe("BankReentrance",() => {
    let bankUser;
    let bank;
    let alice;
    let bob;
    before(async ()=>{
        const BankFactory = await ethers.getContractFactory("Bank");
        const BankUserFactory = await ethers.getContractFactory("BankUser");
        [alice,bob] = await ethers.getSigners();  
        bank = await BankFactory.connect(alice).deploy({value:4});
        bankUser = await BankUserFactory.connect(bob).deploy(); 
        await bankUser.setup(bank.address);
        await bankUser.deposit({value:2,from:bob.address});
    })

    it('should have balance', async () => {
        const bankBalance = await bank.getBalance();
        const bankUserBalance = await bank.balances(bankUser.address);
        assert.equal(bankUserBalance,2);
        assert.equal(bankBalance,6);
    })

    it('should be able to attack bank' ,async () => {
        await bankUser.withdraw(1,{from:bob.address});
        const bankBalance = await bank.getBalance();
        const bankUserBalance = await bankUser.getBalance();
        assert(bankUserBalance,6);
        assert.equal(bankBalance,0);
    })

})