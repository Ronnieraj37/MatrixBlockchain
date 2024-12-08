import {
  ChainSlug,
  ChainSocketAddresses,
  DeploymentAddresses,
} from "@socket.tech/dl-core";
import { getProviderFromChainSlug } from "../constants";
import { Contract, Wallet } from "ethers";
import { getInstance } from "./utils";
import dev_addresses from "../../deployments/dev_addresses.json";

const chain = ChainSlug.ARBITRUM_SEPOLIA;
const to = "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC";
const amount = "1000000000000000000";

export const main = async () => {
  let addresses: DeploymentAddresses;
  try {
    addresses = dev_addresses as unknown as DeploymentAddresses;

    if (!addresses[chain]) return;

    const providerInstance = getProviderFromChainSlug(chain);
    const socketSigner: Wallet = new Wallet(
      process.env.SOCKET_SIGNER_KEY as string,
      providerInstance
    );

    const addr: ChainSocketAddresses = addresses[chain]!;
    if (!addr["integrations"]) return;

    const token: Contract = (
      await getInstance("SuperToken", addr["SuperToken"])
    ).connect(socketSigner);

    const tx = await token.transfer(to, amount);

    console.log(
      `tokens transferred from ${socketSigner.address} to ${to} on ${chain} at tx hash: ${tx.hash}`
    );
    await tx.wait();
  } catch (error) {
    console.log("Error while sending transaction", error);
  }
};

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
