import fs from "fs";
import dotenv from "dotenv";
dotenv.config();
import { getProviderFromChainSlug } from "../constants/networks";
import path from "path";
import { ethers } from "ethers";
const DEPLOYMENT_FILE = path.join(
  __dirname,
  "../../deployments/dev_addresses.json"
);

async function updateLastBlocks() {
  // Read deployment addresses
  const addresses = JSON.parse(fs.readFileSync(DEPLOYMENT_FILE, "utf8"));

  const chains = Object.keys(addresses).map((chainSlug) => Number(chainSlug));
  // Update each chain's start block
  for (const chainSlug of chains) {
    const chainAddresses = addresses[chainSlug];
    try {
      let provider = getProviderFromChainSlug(chainSlug);
      // Get latest block
      const latestBlock = await provider.getBlockNumber();
      console.log({
        chainSlug,
        currentStartBlock: chainAddresses.startBlock,
        latestBlock,
      });
      // Update start block
      chainAddresses.startBlock = latestBlock;

      console.log(`Updated chain ${chainSlug} start block to ${latestBlock}`);
    } catch (error) {
      console.error(`Error updating chain ${chainSlug}:`, error);
    }
  }

  // Write updated data back to file
  fs.writeFileSync(DEPLOYMENT_FILE, JSON.stringify(addresses, null, 2));
  console.log("Successfully updated start blocks in deployment file");
}

// Run the update
updateLastBlocks()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
