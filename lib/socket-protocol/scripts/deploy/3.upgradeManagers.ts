import {
  ChainSocketAddresses,
  CORE_CONTRACTS,
  DeploymentAddresses,
  DeploymentMode,
} from "@socket.tech/dl-core";

import { config as dotenvConfig } from "dotenv";
dotenvConfig();

import { ethers } from "hardhat";
import dev_addresses from "../../deployments/dev_addresses.json";
import { chains } from "./config";
import { getProviderFromChainSlug } from "../constants";
import { constants, Contract, Wallet } from "ethers";
import { getInstance, storeAddresses } from "./utils";

export const main = async () => {
  let addresses: DeploymentAddresses;
  try {
    console.log("Upgrading Managers");
    addresses = dev_addresses as unknown as DeploymentAddresses;

    for (const chain of chains) {
      let chainAddresses: ChainSocketAddresses = addresses[chain]
        ? (addresses[chain] as ChainSocketAddresses)
        : ({} as ChainSocketAddresses);

      const providerInstance = getProviderFromChainSlug(chain);
      const signer: Wallet = new ethers.Wallet(
        process.env.SOCKET_SIGNER_KEY as string,
        providerInstance
      );

      const socketContract = (
        await getInstance("Socket", chainAddresses[CORE_CONTRACTS.Socket])
      ).connect(signer);

      await registerSb(
        chainAddresses[CORE_CONTRACTS.FastSwitchboard],
        signer,
        socketContract
      );

      await storeAddresses(chainAddresses, chain, DeploymentMode.DEV);
    }
  } catch (error) {
    console.log("Error:", error);
  }
};

const registerSb = async (sbAddress, signer, socket) => {
  try {
    // used fast switchboard here as all have same function signature
    const switchboard = (
      await getInstance("FastSwitchboard", sbAddress)
    ).connect(signer);

    // send overrides while reading capacitor to avoid errors on mantle chain
    // some chains give balance error if gas price is used with from address as zero
    // therefore override from address as well
    let sb = await socket.isValidSwitchboard(sbAddress, {
      from: signer.address,
    });

    if (!sb) {
      const registerTx = await switchboard.registerSwitchboard();
      console.log(`Registering Switchboard ${sbAddress}: ${registerTx.hash}`);
      await registerTx.wait();
    }
  } catch (error) {
    throw error;
  }
};

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
