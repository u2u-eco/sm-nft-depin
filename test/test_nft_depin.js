const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { weeks } = require("@nomicfoundation/hardhat-network-helpers/dist/src/helpers/time/duration");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const {v4: uuidv4} = require("uuid");

function getCurrentTime() {
    return Math.floor(Date.now() / 1000);
}

describe("NFTDePIN", function() {

    async function getBlockLatest() {
        return await ethers.provider.getBlock("latest");
    }

    async function getBlockTimeStamp() {
        const blockLatest = await getBlockLatest();
        return blockLatest.timestamp;
    }

    async function startImpersonateAccount(params) {
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [params],
        });
    }

    async function stopImpersonateAccount(params) {
        await hre.network.provider.request({
            method: "hardhat_stopImpersonatingAccount",
            params: [params],
        });
    }

    async function increaseTimeTo(timeAt) {
        await time.increaseTo(timeAt);
    }
    
    let NFTDePIN;
    let nftDepinContract;
    let owner, user, signer;

    const NFT_NAME = "U2U DePIN Subnet Node";
    const NFT_SYMBOL = "DEPIN";
    const TIME_LOCK_DEFAULT =  6 * 4 * weeks;
    const ADDRESS_ZERO = ethers.ZeroAddress;
    const PREFIX_MESSAGE = "DP_NFT_GENERATE";


    const MSG_OWNER = "Ownable: caller is not the owner";
    const MSG_SIGNATURE_INVALID = "DP: signer invalid";

    before(async function () {
        [owner, user, signer, ownerNew] = await ethers.getSigners();
    });

    beforeEach(async function () {
        NFTDePIN = await ethers.getContractFactory("NFTDePIN");
        nftDepinContract = await NFTDePIN.deploy();
        await nftDepinContract.addWhiteList(ADDRESS_ZERO);
    });
    
    async function minedBlock(numberBlock) {
        const numberHex = ethers.BigNumber.from(numberBlock.toString()).toHexString().replace('0x0','0x');
        await hre.network.provider.send("hardhat_mine", [numberHex]);
    }
    async function increaseTimeTo(timeAt) {
        await time.increaseTo(timeAt);
    }
    async function allowanceContract(tokenContract, sender, spenderAddress, amountAllowance) {
        await tokenContract.connect(sender).approve(spenderAddress, amountAllowance);
    }

    describe("Owner", function() {
        describe("Deploy", function() {
            it("Contract deploy success", async function() {
              const userDeploy = await nftDepinContract.owner();
              expect(userDeploy.address, owner.address);
              const timeLock = await nftDepinContract.LOCK_TIME();
              expect(timeLock, TIME_LOCK_DEFAULT);
              const name = await nftDepinContract.name();
              expect(name, NFT_NAME);
              const symbol = await nftDepinContract.symbol();
              expect(symbol, NFT_SYMBOL);
            });
        });
        describe("TransferOwner", function() {
            it("Transfer owner should be success", async function () {
                const ownerCurrent = await nftDepinContract.owner();
                await expect(nftDepinContract.transferOwnership(ownerNew.address))
                    .to.be.emit(nftDepinContract, "OwnershipTransferred")
                    .withArgs(ownerCurrent, ownerNew.address);
            });
            it("Renounce Ownership should be success", async function () {
                const ownerBefore = await nftDepinContract.owner();
                await expect(nftDepinContract.renounceOwnership())
                    .to.be.emit(nftDepinContract, "OwnershipTransferred")
                    .withArgs(ownerBefore, ADDRESS_ZERO);
                const ownerNew = await nftDepinContract.owner();
                expect(ADDRESS_ZERO, ownerNew);
            });
        });
        describe("Add or remove whitelist", function() {
            it("Add whitelist should be success", async function() {
                const userStatusBeforeUpdate = await nftDepinContract.whitelist(user.address);
                expect(userStatusBeforeUpdate, false);
                await expect(nftDepinContract.addWhiteList(user.address))
                    .to.be.emit(nftDepinContract, "WhiteListUpdated")
                    .withArgs(user.address, true);
                const userStatusAfterUpdate = await nftDepinContract.whitelist(user.address);
                expect(userStatusAfterUpdate, true);
            });
            it("Remove whitelist should be success", async function() {
                await expect(nftDepinContract.addWhiteList(user.address))
                    .to.be.emit(nftDepinContract, "WhiteListUpdated")
                    .withArgs(user.address, true);
                const userStatusAfterAdd = await nftDepinContract.whitelist(user.address);
                expect(userStatusAfterAdd, true);
                await expect(nftDepinContract.removeWhiteList(user.address))
                    .to.be.emit(nftDepinContract, "WhiteListUpdated")
                    .withArgs(user.address, false);
                const statusAfterRemove = await nftDepinContract.whitelist(user.address);
                expect(statusAfterRemove, false);
            });
        });
        describe("Add, remove blacklist", function() {
            it("Add blacklist should be success", async function() {
                const userStatusBeforeAdd = await nftDepinContract.isBlackListed(user.address);
                await expect(nftDepinContract.addBlackList(user.address))
                    .to.be.emit(nftDepinContract, "BlackListUpdated")
                    .withArgs(user.address, true);
                const userStatusAfterAdd = await nftDepinContract.isBlackListed(user.address);
                expect(userStatusBeforeAdd, false);
                expect(userStatusAfterAdd, true);
            });
            it("Remove blacklist should be success", async function() {
                await expect(nftDepinContract.addBlackList(user.address))
                .to.be.emit(nftDepinContract, "BlackListUpdated")
                .withArgs(user.address, true);
                await expect(nftDepinContract.removeBlackList(user.address))
                    .to.be.emit(nftDepinContract, "BlackListUpdated")
                    .withArgs(user.address, false);
            });
        });
        it("Mint token should be success", async function () {
            const tokenId = await nftDepinContract.idGenerate();
            console.log(tokenId)
            await expect(nftDepinContract.safeMint(user.address))
                .to.be.emit(nftDepinContract, "Transfer")
                .withArgs(ADDRESS_ZERO, user.address, tokenId+BigInt(1));
        });
    });
    

    
    
});