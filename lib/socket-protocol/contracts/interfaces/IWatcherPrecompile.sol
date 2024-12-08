// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {PayloadDetails, AsyncRequest, FinalizeParams, PayloadRootParams} from "../common/Structs.sol";

/// @title IWatcherPrecompile
/// @notice Interface for the Watcher Precompile system that handles payload verification and execution
/// @dev Defines core functionality for payload processing and promise resolution
interface IWatcherPrecompile {
    /// @notice Configuration struct for app gateway setup
    /// @param chainSlug The identifier of the destination network
    /// @param appGateway The address of the app gateway
    /// @param plug The address of the plug
    /// @param switchboard The address of the switchboard
    struct AppGatewayConfig {
        uint32 chainSlug;
        address appGateway;
        address plug;
        address switchboard;
    }

    /// @notice Configuration struct for plug settings
    /// @param appGateway The address of the app gateway
    /// @param switchboard The address of the switchboard
    struct PlugConfig {
        address appGateway;
        address switchboard;
    }

    /// @notice Struct for resolved promise data
    /// @param payloadId The unique identifier for the payload
    /// @param returnData Array of return data from resolved promises
    struct ResolvedPromises {
        bytes32 payloadId;
        bytes[] returnData;
    }

    /// @notice Sets up app gateway configurations
    /// @param configs Array of app gateway configurations
    /// @dev Only callable by authorized addresses
    function setAppGateways(AppGatewayConfig[] calldata configs) external;

    /// @notice Retrieves plug configuration for a specific network and plug
    /// @param chainSlug_ The identifier of the network
    /// @param plug_ The address of the plug
    /// @return appGateway The configured app gateway address
    /// @return switchboard The configured switchboard address
    function getPlugConfigs(
        uint32 chainSlug_,
        address plug_
    ) external view returns (address appGateway, address switchboard);

    /// @notice Finalizes a payload execution request
    /// @param params_ Parameters needed for finalization
    /// @return payloadId The unique identifier for the request
    /// @return root The merkle root of the payload parameters
    function finalize(
        FinalizeParams memory params_
    ) external returns (bytes32 payloadId, bytes32 root);

    /// @notice Creates a new query request
    /// @param chainSlug The identifier of the destination network
    /// @param targetAddress The address of the target contract
    /// @param asyncPromises Array of promise addresses to be resolved
    /// @param payload The query payload data
    /// @return payloadId The unique identifier for the query
    function query(
        uint32 chainSlug,
        address targetAddress,
        address[] memory asyncPromises,
        bytes memory payload
    ) external returns (bytes32 payloadId);

    /// @notice Marks a request as finalized with a signature
    /// @param payloadId_ The unique identifier of the request
    /// @param signature_ The watcher's signature
    function finalized(bytes32 payloadId_, bytes calldata signature_) external;

    /// @notice Resolves multiple promises with their return data
    /// @param resolvedPromises_ Array of resolved promises and their return data
    function resolvePromises(
        ResolvedPromises[] calldata resolvedPromises_
    ) external;

    /// @notice Sets a timeout for payload execution
    /// @param payload_ The payload data
    /// @param timeoutMS_ The timeout duration in milliseconds
    function setTimeout(bytes calldata payload_, uint256 timeoutMS_) external;

    /// @notice Resolves a timeout by executing the payload
    /// @param target_ The target address for execution
    /// @param payload_ The payload to execute
    /// @param timeoutMS The original timeout duration
    function resolveTimeout(
        address target_,
        bytes calldata payload_,
        uint256 timeoutMS
    ) external;
    /// @notice Calculates the root hash for payload parameters
    /// @param params_ The payload parameters used to calculate the root
    /// @return root The calculated merkle root hash
    function getRoot(
        PayloadRootParams memory params_
    ) external pure returns (bytes32 root);

    /// @notice Gets the plug address for a given app gateway and chain
    /// @param appGateway_ The address of the app gateway contract
    /// @param chainSlug_ The identifier of the destination chain
    /// @return The plug address for the given app gateway and chain
    function appGatewayPlugs(
        address appGateway_,
        uint32 chainSlug_
    ) external view returns (address);
}
