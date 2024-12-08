import {
  ChainSocketAddresses,
  CORE_CONTRACTS,
  DeploymentAddresses,
} from "@socket.tech/dl-core";
import { getProviderFromChainSlug } from "../constants";
import { Contract, ethers, providers, Wallet } from "ethers";
import { getInstance } from "./utils";
import WatcherABI from "../../out/WatcherPrecompile.sol/WatcherPrecompile.json";
import SocketABI from "../../out/Socket.sol/Socket.json";
import { chains, overrides, WatcherVMCoreContracts } from "./config";
import dev_addresses from "../../deployments/dev_addresses.json";
import { OFF_CHAIN_VM_CHAIN_ID } from "../constants/constants";

export const main = async () => {
  let addresses: DeploymentAddresses;
  try {
    console.log("Connecting plugs");
    addresses = dev_addresses as unknown as DeploymentAddresses;

    await Promise.all(
      chains.map(async (chain) => {
        if (!addresses[chain]) return;

        const providerInstance = getProviderFromChainSlug(chain);
        const socketSigner: Wallet = new Wallet(
          process.env.SOCKET_SIGNER_KEY as string,
          providerInstance
        );

        const addr: ChainSocketAddresses = addresses[chain]!;
        const watcherVMaddr: ChainSocketAddresses =
          addresses[OFF_CHAIN_VM_CHAIN_ID]!;
        // if (!addr["integrations"]) return;

        const plugs = ["PayloadDeliveryPlug"];
        // const plugs = ["ConnectorPlug", "PayloadDeliveryPlug"];
        for (const plugContract of plugs) {
          console.log(`Connecting ${plugContract} on ${chain}`);
          const plug: Contract = (
            await getInstance(plugContract, addr[plugContract])
          ).connect(socketSigner);

          const socket = new Contract(
            addr[CORE_CONTRACTS.Socket],
            SocketABI.abi,
            socketSigner
          );

          const switchboard = addr["FastSwitchboard"];
          if (!switchboard) continue;
          const appGateway =
            plugContract === "ConnectorPlug"
              ? watcherVMaddr["SuperTokenApp"]
              : watcherVMaddr["AuctionHouse"];

          console.log(
            `Connecting ${plugContract} on ${chain} plug:  ${plug.address}`
          );
          const configs = await socket.getPlugConfig(plug.address);
          console.log({ configs });
          if (
            configs[0].toLowerCase() === appGateway?.toLowerCase() &&
            configs["switchboard__"].toLowerCase() === switchboard.toLowerCase()
          ) {
            console.log("Config already set!");
            continue;
          }

          const tx = await plug.functions["connect"](
            appGateway,
            switchboard
            // { ...(await overrides(chain)) }
          );

          console.log(`Connecting applicationGateway tx hash: ${tx.hash}`);
          await tx.wait();
        }
      })
    );

    await updateConfigWatcherVM();
  } catch (error) {
    console.log("Error while sending transaction", error);
  }
};

export const updateConfigWatcherVM = async () => {
  let addresses: DeploymentAddresses;
  try {
    console.log("Connecting plugs on OffChainVM");
    addresses = dev_addresses as unknown as DeploymentAddresses;

    const appConfigs: {
      plug: string;
      chainSlug: number;
      appGateway: string;
      switchboard: string;
    }[] = [];

    const providerInstance = new providers.StaticJsonRpcProvider(
      process.env.OFF_CHAIN_VM_RPC as string
    );

    const signer: Wallet = new ethers.Wallet(
      process.env.WATCHER_PRIVATE_KEY as string,
      providerInstance
    );
    const watcherVMaddr: ChainSocketAddresses =
      addresses[OFF_CHAIN_VM_CHAIN_ID]!;

    const watcher = new Contract(
      watcherVMaddr[WatcherVMCoreContracts.WatcherPrecompile],
      WatcherABI.abi,
      signer
    );
    await Promise.all(
      chains.map(async (chain) => {
        if (!addresses[chain]) return;
        const addr: ChainSocketAddresses = addresses[chain]!;

        const plugs = ["PayloadDeliveryPlug"];
        // const plugs = ["ConnectorPlug", "PayloadDeliveryPlug"];
        for (const plugContract of plugs) {
          const appGateway =
            plugContract === "ConnectorPlug"
              ? watcherVMaddr["SuperTokenApp"]
              : watcherVMaddr["AuctionHouse"];

          appConfigs.push({
            plug: addr[plugContract],
            appGateway,
            switchboard: addr["FastSwitchboard"],
            chainSlug: chain,
          });
        }
      })
    );

    console.log(appConfigs);
    // return;
    if (appConfigs.length == 0) return;
    const tx = await watcher.setAppGateways(appConfigs);
    console.log(`Updating OffChainVM Config tx hash: ${tx.hash}`);
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
