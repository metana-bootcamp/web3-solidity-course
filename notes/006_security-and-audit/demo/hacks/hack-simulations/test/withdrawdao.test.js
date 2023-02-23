const {assert} = require("chai");

const withdrawDAOAddr = "0xbf4ed7b27f1d666546e30d74d50d173d20bca754";
const holder =  "0x981e7512e87d2f7228d3f03b65950eb6a1b21bac";

describe("DaoHackWithdrawal", () => {
    it("should exchange our dao tokens", async () => {
        const withdrawDAO = await ethers.getContractFactory("WithdrawDAO");
        const contract = await withdrawDAO.attach(withdrawDAOAddr);

        const balanceBefore = await ethers.provider.getBalance(holder);

        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [holder]
        })

        const signer = ethers.provider.getSigner(holder);
        
        contract.connect(signer).withdraw();

        const balanceAfter = await ethers.provider.getBalance(holder);

        console.log(ethers.utils.formatEther(balanceAfter.sub(balanceBefore)));

        assert(balanceAfter.gt(balanceBefore));
    })
})