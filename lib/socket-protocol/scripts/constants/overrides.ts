import { ChainSlug } from "@socket.tech/dl-core";
import { BigNumber, providers } from "ethers";

const defaultType = 0;

export const chainOverrides: {
  [chainSlug in ChainSlug]?: {
    type?: number;
    gasLimit?: number;
    gasPrice?: number;
  };
} = {
  [ChainSlug.ARBITRUM_SEPOLIA]: {
    type: 1,
    gasLimit: 50_000_000,
    gasPrice: 200_000_000,
  },
  [ChainSlug.SEPOLIA]: {
    type: 1,
    gasLimit: 2_000_000,
    // gasPrice: 50_000_000_000, // calculate in real time
  },
  [ChainSlug.OPTIMISM_SEPOLIA]: {
    // type: 1,
    // gasLimit: 1_000_000,
    // gasPrice: 212_000_000_000,
  },
};

export const getOverrides = async (
  chainSlug: ChainSlug,
  provider: providers.StaticJsonRpcProvider
) => {
  let overrides = chainOverrides[chainSlug];
  let gasPrice = overrides?.gasPrice;
  let gasLimit = overrides?.gasLimit;
  let type = overrides?.type;
  if (!gasPrice) gasPrice = (await getGasPrice(chainSlug, provider)).toNumber();
  if (type == undefined) type = defaultType;
  // if gas limit is undefined, ethers will calcuate it automatically. If want to override,
  // add in the overrides object. Dont set a default value
  return { gasLimit, gasPrice, type };
};

export const getGasPrice = async (
  chainSlug: ChainSlug,
  provider: providers.StaticJsonRpcProvider
): Promise<BigNumber> => {
  let gasPrice = await provider.getGasPrice();

  if ([ChainSlug.SEPOLIA].includes(chainSlug as ChainSlug)) {
    return gasPrice.mul(BigNumber.from(150)).div(BigNumber.from(100));
  }
  return gasPrice;
};
