const { assert,expect } = require("chai");
const { ethers } = require("hardhat");

describe("Dos", () => {
    let kingOfEther;
    let attack;
    let deployer;
    let alice;
    let bob;
    let attacker;
    before(async () => {
        const KingOfEtherFactory = await ethers.getContractFactory("KingOfEther");
        const AttackFactory = await ethers.getContractFactory("Attack");
        [deployer, alice, bob, attacker] = await ethers.getSigners();
        kingOfEther = await KingOfEtherFactory.connect(deployer).deploy();
        attack = await AttackFactory.connect(attacker).deploy(kingOfEther.address);
    })

    it('alice and bob should be king of ether sequentially', async () => {
        await kingOfEther.connect(alice).claimThrone({ value: ethers.constants.WeiPerEther })
        let king = await kingOfEther.king();
        assert.equal(king, alice.address);
        await kingOfEther.connect(bob).claimThrone({ value: ethers.constants.WeiPerEther.mul(2) })
        king = await kingOfEther.king();
        assert.equal(king, bob.address);
    })

    it('attack should cause DoS on KingOfEther', async () => {
        await attack.attack({ value: ethers.constants.WeiPerEther.mul(3) });
        let king = await kingOfEther.king();
        assert.equal(king, attack.address);
        await expect(kingOfEther.connect(alice).claimThrone({ value: ethers.constants.WeiPerEther.mul(4) })).to.be.revertedWith("");
    })

})