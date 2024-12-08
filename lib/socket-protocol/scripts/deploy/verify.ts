import hre from "hardhat";
import { storeUnVerifiedParams, verify } from "./utils/utils";
import {
  HardhatChainName,
  ChainSlugToKey,
  ChainSlug,
  DeploymentMode,
} from "@socket.tech/dl-core";
import path from "path";
import fs from "fs";
import {
  BASE_SEPOLIA_CHAIN_ID,
  OFF_CHAIN_VM_CHAIN_ID,
} from "../constants/constants";

export type VerifyParams = {
  [chain in HardhatChainName]?: VerifyArgs[];
};
export type VerifyArgs = [string, string, string, any[]];
const deploymentsPath = path.join(__dirname, `/../../deployments/`);

/**
 * Deploys network-independent socket contracts
 */
export const main = async () => {
  try {
    const path = deploymentsPath + `dev_verification.json`;
    if (!fs.existsSync(path)) {
      throw new Error("addresses.json not found");
    }
    let verificationParams: VerifyParams = JSON.parse(
      fs.readFileSync(path, "utf-8")
    );

    const chains = Object.keys(verificationParams);
    if (!chains) return;

    for (let chainIndex = 0; chainIndex < chains.length; chainIndex++) {
      const chain = parseInt(chains[chainIndex]) as ChainSlug;
      let chainName: string;
      console.log({ chain });
      if (chain == (BASE_SEPOLIA_CHAIN_ID as ChainSlug)) {
        chainName = "base_sepolia";
      } else if (chain == (OFF_CHAIN_VM_CHAIN_ID as ChainSlug)) {
        chainName = "OFF_CHAIN_VM";
      } else {
        chainName = ChainSlugToKey[chain];
      }
      console.log({ chainName });
      hre.changeNetwork(chainName);
      console.log(chainName);

      const chainParams: VerifyArgs[] = verificationParams[chain];
      const unverifiedChainParams: VerifyArgs[] = [];
      if (chainParams.length) {
        const len = chainParams.length;
        for (let index = 0; index < len!; index++) {
          const res = await verify(...chainParams[index]);
          if (!res) {
            unverifiedChainParams.push(chainParams[index]);
          }
        }
      }

      await storeUnVerifiedParams(
        unverifiedChainParams,
        chain,
        DeploymentMode.DEV
      );
    }
  } catch (error) {
    console.log("Error in verifying contracts", error);
  }
};

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
