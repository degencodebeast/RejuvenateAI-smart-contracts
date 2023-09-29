import { Wallet, getDefaultProvider } from "ethers";
//require('dotenv').config()
import { ethers } from "hardhat";
import { NutritionistNFT__factory, UserNFT__factory, Treasury__factory, CommunityFVM__factory, CommunityLilypad__factory, CommunityChainlink__factory } from "../typechain-types";

//const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
//const wallet = new ethers.Wallet(PRIVATE_KEY, ethers.provider);

const privateKey = process.env.PRIVATE_KEY as string;
const wallet = new Wallet(privateKey);

const rpc = "https://filecoin-calibration.chainstacklabs.com/rpc/v1	";
const modicumContract = "0x422F325AA109A3038BDCb7B03Dd0331A4aC2cD1a";
const mumbaiRegistryAddr = "0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2"
const mumbaiRegistrarAddr = "0x57A4a13b35d25EE78e084168aBaC5ad360252467"
const linkTokenAddr = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB";

async function main() {
    await deployCommunityFVMContracts();
    //await deployCommunityLilypadContracts();
    //await deployCommunityChainlinkContracts();
}

async function deployTreasury() {
    //console.log("Deploying Treasury....");

    //const provider = getDefaultProvider(rpc)
    //const connectedWallet = wallet.connect(provider);
    //const TreasuryFactory = new Treasury__factory(connectedWallet);

    const TreasuryFactory: Treasury__factory = await ethers.getContractFactory("Treasury");
    const treasury = await TreasuryFactory.deploy();
    await treasury.deployed();
    console.log("---- Treasury Contract was deployed to: ---- ", treasury.address);
    return treasury.address;
}

async function deployUserNFT(_communityAddr: any) {
    //console.log("Deploying UserNFT....");
    const UserNFTFactory: UserNFT__factory = await ethers.getContractFactory("UserNFT");
    const userNFT = await UserNFTFactory.deploy("User NFT", "UST", _communityAddr);
    await userNFT.deployed();
    console.log("---- UserNFT Contract was deployed to: ---- ", userNFT.address);
    return userNFT.address;
}

async function deployNutritionistNFT(_communityAddr: any) {
    //console.log("Deploying NutrionistNFT....");
    const NutritionistNFTFactory: NutritionistNFT__factory = await ethers.getContractFactory("NutritionistNFT");
    const nutritionistNFT = await NutritionistNFTFactory.deploy("Nutritionist NFT", "NUT", _communityAddr);
    await nutritionistNFT.deployed();
    console.log("---- NutritionistNFT Contract was deployed to: ---- ", nutritionistNFT.address);
    return nutritionistNFT.address;
}

async function deployCommunityLilypadContracts() {

    console.log("Deploying Contracts for Lilypad....");
    let treasuryAddr;
    let communityAddr;
    try {
        console.log("Deploying treasury for Lilypad");
        treasuryAddr = await deployTreasury();

        console.log("Deploying Community contract for Lilypad");
        const CommunityLilypadFactory: CommunityLilypad__factory = await ethers.getContractFactory("CommunityLilypad"/*, wallet*/);
        const communitylilypad = await CommunityLilypadFactory.deploy(treasuryAddr, modicumContract);
        await communitylilypad.deployed();
        communityAddr = communitylilypad.address;
        console.log("---- Community Contract for Lilypad was deployed to the lalechuza testnet at this address: ---- ", communitylilypad.address);

    }
    catch (error) {
        console.error("Error deploying Community for Lilypad:", error);
        throw error;
    }

    console.log("Deploying UserNFT for Lilypad....");

    let userNFT;
    try {
        userNFT = await deployUserNFT(communityAddr);
    }
    catch (error) {
        console.error("Error User NFT for Lilypad:", error);
        throw error;
    }

    console.log("Deploying NutritionistNFT for Lilypad....");

    let nutritionistNFT;
    try {
        nutritionistNFT = await deployNutritionistNFT(communityAddr);
    }
    catch (error) {
        console.error("Error Nutritionist NFT for Lilypad:", error);
        throw error;
    }
}

async function deployCommunityChainlinkContracts() {

    console.log("Deploying Contracts for Chainlink....");
    let treasuryAddr;
    let communityAddr;
    try {
        console.log("Deploying treasury for Chainlink");
        treasuryAddr = await deployTreasury();

        console.log("Deploying Community contract for Chainlink");
        const CommunityChainlinkFactory: CommunityChainlink__factory = await ethers.getContractFactory("CommunityChainlink"/*, wallet*/);
        const communityChainlink = await CommunityChainlinkFactory.deploy(treasuryAddr, linkTokenAddr, mumbaiRegistrarAddr, mumbaiRegistryAddr);
        await communityChainlink.deployed();
        communityAddr = communityChainlink.address;
        console.log("---- Community Contract for Chainlink was deployed to polygon at this address: ---- ", communityChainlink.address);

    }
    catch (error) {
        console.error("Error deploying Community for Chainlink:", error);
        throw error;
    }

    console.log("Deploying UserNFT for Chainlink....");

    let userNFT;
    try {
        userNFT = await deployUserNFT(communityAddr);
    }
    catch (error) {
        console.error("Error User NFT for Chainlink:", error);
        throw error;
    }

    console.log("Deploying NutritionistNFT for Chainlink....");

    let nutritionistNFT;
    try {
        nutritionistNFT = await deployNutritionistNFT(communityAddr);
    }
    catch (error) {
        console.error("Error Nutritionist NFT for Chainlink:", error);
        throw error;
    }
}

async function deployCommunityFVMContracts() {
    console.log("Deploying Contracts for FVM....");
    let treasuryAddr;
    let communityAddr;
    try {
        console.log("Deploying treasury for FVM");
        treasuryAddr = await deployTreasury();

        const CommunityFVMFactory: CommunityFVM__factory = await ethers.getContractFactory("CommunityFVM"/*, wallet*/);

        console.log("Deploying Community contract for FVM");
        const communityFVM = await CommunityFVMFactory.deploy(treasuryAddr);
        await communityFVM.deployed();
        communityAddr = communityFVM.address;
        console.log("---- Community Contract for FVM was deployed to calibration testnet at this address: ---- ", communityFVM.address);
    }
    catch (error) {
        console.error("Error deploying Community for FVM:", error);
        throw error;
    }

    console.log("Deploying UserNFT for FVM....");
    let userNFT;
    try {
        userNFT = await deployUserNFT(communityAddr);
    }
    catch (error) {
        console.error("Error User NFT for FVM:", error);
        throw error;
    }

    console.log("Deploying NutritionistNFT for FVM....");
    let nutritionistNFT;
    try {
        nutritionistNFT = await deployNutritionistNFT(communityAddr);
    }
    catch (error) {
        console.error("Error Nutritionist NFT for FVM:", error);
        throw error;
    }


}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
