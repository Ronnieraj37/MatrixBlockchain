// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./IWatcherPrecompile.sol";

/// @title IAddressResolver
/// @notice Interface for resolving system contract addresses
/// @dev Provides address lookup functionality for core system components
interface IAddressResolver {
    /// @notice Emitted when a new address is set in the resolver
    /// @param name The identifier of the contract
    /// @param oldAddress The previous address of the contract
    /// @param newAddress The new address of the contract
    event AddressSet(
        bytes32 indexed name,
        address oldAddress,
        address newAddress
    );

    /// @notice Gets the address of the auction house contract
    /// @return IAuctionHouse The auction house interface
    /// @dev Returns interface pointing to zero address if not configured
    function auctionHouse() external view returns (address);

    /// @notice Gets the watcher precompile contract interface
    /// @return IWatcherPrecompile The watcher precompile interface
    /// @dev Returns interface pointing to zero address if not configured
    function watcherPrecompile() external view returns (IWatcherPrecompile);

    /// @notice Maps contract addresses to their corresponding gateway addresses
    /// @param contractAddress The address of the contract to lookup
    /// @return The gateway address associated with the contract
    function contractsToGateways(
        address contractAddress
    ) external view returns (address);

    /// @notice Maps gateway addresses to their corresponding contract addresses
    /// @param gatewayAddress The address of the gateway to lookup
    /// @return The contract address associated with the gateway
    function gatewaysToContracts(
        address gatewayAddress
    ) external view returns (address);

    /// @notice Gets the list of all deployed async promise contracts
    /// @return Array of async promise contract addresses
    function getPromises() external view returns (address[] memory);

    // State-changing functions

    /// @notice Sets the auction house contract address
    /// @param _auctionHouse The new auction house contract address
    /// @dev Only callable by contract owner
    function setAuctionHouse(address _auctionHouse) external;

    /// @notice Sets the watcher precompile contract address
    /// @param _watcherPrecompile The new watcher precompile contract address
    /// @dev Only callable by contract owner
    function setWatcherPrecompile(address _watcherPrecompile) external;

    /// @notice Maps a contract address to its gateway
    /// @param contractAddress_ The contract address to map
    /// @dev Creates bidirectional mapping between contract and gateway
    function setContractsToGateways(address contractAddress_) external;

    /// @notice Clears the list of deployed async promise contracts
    /// @dev Only callable by contract owner
    function clearPromises() external;

    /// @notice Deploys a new forwarder contract
    /// @param appDeployer_ The app deployer contract address
    /// @param chainContractAddress_ The contract address on the destination chain
    /// @param chainSlug_ The identifier of the destination chain
    /// @return The address of the newly deployed forwarder contract
    function deployForwarderContract(
        address appDeployer_,
        address chainContractAddress_,
        uint32 chainSlug_
    ) external returns (address);

    /// @notice Deploys a new async promise contract
    /// @param invoker_ The address that can invoke/execute the promise
    /// @return The address of the newly deployed async promise contract
    function deployAsyncPromiseContract(
        address invoker_
    ) external returns (address);
}
