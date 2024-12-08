import { config as dotenvConfig } from "dotenv";
dotenvConfig();

import { ChainSlug, DeploymentMode, version } from "@socket.tech/dl-core";
import { BigNumberish, utils } from "ethers";
import { getOverrides } from "../constants/overrides";
import { getProviderFromChainSlug } from "../constants";
import { BASE_SEPOLIA_CHAIN_ID } from "../constants/constants";

export const mode = process.env.DEPLOYMENT_MODE as
  | DeploymentMode
  | DeploymentMode.DEV;

console.log(
  "================================================================================================================"
);
console.log("");
console.log(`Mode: ${mode}`);
console.log(`Version: ${version[mode]}`);
console.log("");
console.log(
  `Make sure ${mode}_addresses.json and ${mode}_verification.json is cleared for given networks if redeploying!!`
);
console.log("");
console.log(
  "================================================================================================================"
);

export const chains: Array<ChainSlug> = [
  ChainSlug.ARBITRUM_SEPOLIA,
  ChainSlug.OPTIMISM_SEPOLIA,
  ChainSlug.SEPOLIA,
  BASE_SEPOLIA_CHAIN_ID as ChainSlug,
];

export const capacitorType = 1;
export const maxPacketLength = 1;
export const initialPacketCount = 0;

const MSG_VALUE_MAX_THRESHOLD = utils.parseEther("0.001");
export const msgValueMaxThreshold = (chain: ChainSlug): BigNumberish => {
  return MSG_VALUE_MAX_THRESHOLD;
};

export const overrides = async (
  chain: ChainSlug | number
): Promise<{
  type?: number | undefined;
  gasLimit?: BigNumberish | undefined;
  gasPrice?: BigNumberish | undefined;
}> => {
  return await getOverrides(chain, getProviderFromChainSlug(chain));
};

export const watcher = "0xb62505feacC486e809392c65614Ce4d7b051923b";

export enum WatcherVMCoreContracts {
  SignatureVerifier = "SignatureVerifier",
  WatcherPrecompile = "WatcherPrecompile",
  AuctionHouse = "AuctionHouse",
  AddressAbstractor = "AddressAbstractor",
  AddressResolver = "AddressResolver",
}

export enum AppContracts {
  SuperTokenApp = "SuperTokenApp",
  SuperTokenDeployer = "SuperTokenDeployer",
}
