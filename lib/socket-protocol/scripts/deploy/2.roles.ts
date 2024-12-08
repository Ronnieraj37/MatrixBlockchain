import {
  ChainSocketAddresses,
  CORE_CONTRACTS,
  DeploymentAddresses,
  ROLES,
} from "@socket.tech/dl-core";

import { config as dotenvConfig } from "dotenv";
dotenvConfig();

import { ethers } from "hardhat";
import dev_addresses from "../../deployments/dev_addresses.json";
import { chains, watcher } from "./config";
import { getProviderFromChainSlug } from "../constants";
import { Wallet } from "ethers";
import { getInstance, getRoleHash } from "./utils";

export const REQUIRED_ROLES = {
  FastSwitchboard: ROLES.WATCHER_ROLE,
  Socket: ROLES.GOVERNANCE_ROLE,
};

export const main = async () => {
  let addresses: DeploymentAddresses;
  try {
    console.log("Setting Roles");
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

      let socket = await getInstance(
        CORE_CONTRACTS.Socket,
        chainAddresses[CORE_CONTRACTS.Socket]!
      );
      socket = socket.connect(signer);

      const hasGovRole = await socket.callStatic["hasRole(bytes32,address)"](
        getRoleHash(REQUIRED_ROLES.Socket),
        signer.address,
        {
          from: signer.address,
        }
      );

      if (!hasGovRole) {
        const tx = await socket.grantRole(
          getRoleHash(REQUIRED_ROLES.Socket),
          signer.address
        );
        console.log("granting gov role", chain, tx.hash);
        await tx.wait();
      }

      let sb = await getInstance(
        CORE_CONTRACTS.FastSwitchboard,
        chainAddresses[CORE_CONTRACTS.FastSwitchboard]!
      );
      sb = sb.connect(signer);

      const hasRole = await sb.callStatic["hasRole(bytes32,address)"](
        getRoleHash(REQUIRED_ROLES.FastSwitchboard),
        watcher,
        {
          from: signer.address,
        }
      );

      if (!hasRole) {
        const tx = await sb.grantWatcherRole(watcher);
        console.log("granting role to watcher", chain, tx.hash);
        await tx.wait();
      }
    }
  } catch (error) {
    console.log("Error:", error);
  }
};

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
