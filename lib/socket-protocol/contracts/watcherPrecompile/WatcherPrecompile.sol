// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./WatcherPrecompileConfig.sol";
import "../interfaces/IAppGateway.sol";
import "../interfaces/IWatcherPrecompile.sol";
import "../interfaces/IPromise.sol";

import {PayloadRootParams, AsyncRequest, FinalizeParams} from "../common/Structs.sol";

/// @title WatcherPrecompile
/// @notice Contract that handles payload verification, execution and app configurations
contract WatcherPrecompile is WatcherPrecompileConfig {
    /// @notice Counter for tracking query requests
    uint256 public queryCounter;
    /// @notice Counter for tracking payload execution requests
    uint256 public payloadCounter;

    /// @notice Mapping to store async requests
    /// @dev payloadId => AsyncRequest struct
    mapping(bytes32 => AsyncRequest) public asyncRequests;

    /// @notice Mapping to store watcher signatures
    /// @dev payloadId => signature bytes
    mapping(bytes32 => bytes) public watcherSignatures;

    /// @notice Error thrown when an invalid chain slug is provided
    error InvalidChainSlug();

    /// @notice Emitted when a new query is requested
    /// @param chainSlug The identifier of the destination chain
    /// @param targetAddress The address of the target contract
    /// @param payloadId The unique identifier for the query
    /// @param payload The query data
    event QueryRequested(
        uint32 chainSlug,
        address targetAddress,
        bytes32 payloadId,
        bytes payload
    );

    /// @notice Emitted when a finalize request is made
    /// @param payloadId The unique identifier for the request
    /// @param asyncRequest The async request details
    event FinalizeRequested(
        bytes32 indexed payloadId,
        AsyncRequest asyncRequest
    );

    /// @notice Emitted when a request is finalized
    /// @param payloadId The unique identifier for the request
    /// @param asyncRequest The async request details
    /// @param watcherSignature The signature from the watcher
    event Finalized(
        bytes32 indexed payloadId,
        AsyncRequest asyncRequest,
        bytes watcherSignature
    );

    /// @notice Emitted when a promise is resolved
    /// @param payloadId The unique identifier for the resolved promise
    event PromiseResolved(bytes32 indexed payloadId);

    /// @notice Emitted when a timeout is requested
    /// @param target The target address for the timeout
    /// @param payload The payload data
    /// @param timeoutMS The timeout duration in milliseconds
    event TimeoutRequested(address target, bytes payload, uint256 timeoutMS);

    /// @notice Emitted when a timeout is resolved
    /// @param target The target address for the timeout
    /// @param payload The payload data
    /// @param timeoutMS The timeout duration in milliseconds
    event TimeoutResolved(address target, bytes payload, uint256 timeoutMS);

    /// @notice Contract constructor
    /// @param _owner Address of the contract owner
    constructor(address _owner) Ownable(_owner) {}

    /// @notice Sets a timeout for a payload execution on app gateway
    /// @param payload_ The payload data
    /// @param timeoutMS_ The timeout duration in milliseconds
    function setTimeout(bytes calldata payload_, uint256 timeoutMS_) external {
        emit TimeoutRequested(msg.sender, payload_, timeoutMS_);
    }

    /// @notice Ends the timeout and calls the target address with the callback payload
    /// @param target_ The target address for execution
    /// @param payload_ The payload to execute
    /// @param timeoutMS The original timeout duration
    /// @dev Only callable by the contract owner
    function resolveTimeout(
        address target_,
        bytes calldata payload_,
        uint256 timeoutMS
    ) external onlyOwner {
        (bool success, ) = address(target_).call(payload_);
        require(success, "Call failed");
        emit TimeoutResolved(target_, payload_, timeoutMS);
    }

    // ================== Finalize functions ==================

    /// @notice Finalizes a payload request, requests the watcher to release the signatures to execute on chain
    /// @param params_ The finalization parameters
    /// @return payloadId The unique identifier for the finalized request
    /// @return root The merkle root of the payload parameters
    function finalize(
        FinalizeParams memory params_
    ) external returns (bytes32 payloadId, bytes32 root) {
        // The app gateway is the caller of this function
        address appGateway = msg.sender;

        // Verify that the app gateway is properly configured for this chain and target
        _verifyConnections(
            params_.payloadDetails.chainSlug,
            params_.payloadDetails.target,
            appGateway
        );

        // Generate a unique payload ID by combining chain, target, and counter
        payloadId = encodePayloadId(
            params_.payloadDetails.chainSlug,
            params_.payloadDetails.target,
            payloadCounter++
        );

        // Construct parameters for root calculation
        PayloadRootParams memory rootParams_ = PayloadRootParams(
            payloadId,
            appGateway,
            params_.transmitter,
            params_.payloadDetails.executionGasLimit,
            params_.payloadDetails.payload
        );

        // Calculate merkle root from payload parameters
        root = getRoot(rootParams_);

        // Get the switchboard address from plug configurations
        (, address switchboard) = getPlugConfigs(
            params_.payloadDetails.chainSlug,
            params_.payloadDetails.target
        );

        // Create and store the async request with all necessary details
        AsyncRequest memory asyncRequest = AsyncRequest(
            params_.payloadDetails.next,
            appGateway,
            params_.transmitter,
            params_.payloadDetails.executionGasLimit,
            params_.payloadDetails.payload,
            switchboard,
            root
        );
        asyncRequests[payloadId] = asyncRequest;
        emit FinalizeRequested(payloadId, asyncRequest);
    }

    // ================== Query functions ==================
    /// @notice Creates a new query request
    /// @param chainSlug The identifier of the destination chain
    /// @param targetAddress The address of the target contract
    /// @param asyncPromises Array of promise addresses to be resolved
    /// @param payload The query payload data
    /// @return payloadId The unique identifier for the query
    function query(
        uint32 chainSlug,
        address targetAddress,
        address[] memory asyncPromises,
        bytes memory payload
    ) public returns (bytes32 payloadId) {
        // Generate unique payload ID from query counter
        payloadId = bytes32(queryCounter++);

        // Create async request with minimal information for queries
        // Note: addresses set to 0 as they're not needed for queries
        AsyncRequest memory asyncRequest = AsyncRequest(
            asyncPromises,
            address(0),
            address(0),
            0,
            payload,
            address(0),
            bytes32(0)
        );
        asyncRequests[payloadId] = asyncRequest;
        emit QueryRequested(chainSlug, targetAddress, payloadId, payload);
    }

    /// @notice Marks a request as finalized with a signature
    /// @param payloadId_ The unique identifier of the request
    /// @param signature_ The watcher's signature
    /// @dev Only callable by the contract owner
    function finalized(
        bytes32 payloadId_,
        bytes calldata signature_
    ) external onlyOwner {
        watcherSignatures[payloadId_] = signature_;
        emit Finalized(payloadId_, asyncRequests[payloadId_], signature_);
    }

    /// @notice Resolves multiple promises with their return data
    /// @param resolvedPromises_ Array of resolved promises and their return data
    /// @dev Only callable by the contract owner
    function resolvePromises(
        ResolvedPromises[] calldata resolvedPromises_
    ) external onlyOwner {
        for (uint256 i = 0; i < resolvedPromises_.length; i++) {
            // Get the array of promise addresses for this payload
            address[] memory next = asyncRequests[
                resolvedPromises_[i].payloadId
            ].next;

            // Resolve each promise with its corresponding return data
            for (uint256 j = 0; j < next.length; j++) {
                IPromise(next[j]).markResolved(
                    resolvedPromises_[i].returnData[j]
                );
            }
            emit PromiseResolved(resolvedPromises_[i].payloadId);
        }
    }

    /// @notice Calculates the root hash of payload parameters
    /// @param params_ The payload parameters
    /// @return root The calculated merkle root
    function getRoot(
        PayloadRootParams memory params_
    ) public pure returns (bytes32 root) {
        root = keccak256(
            abi.encode(
                params_.payloadId,
                params_.appGateway,
                params_.transmitter,
                params_.executionGasLimit,
                params_.payload
            )
        );
    }

    /// @notice Verifies the connection between chain slug, target, and app gateway
    /// @param chainSlug_ The identifier of the chain
    /// @param target_ The target address
    /// @param appGateway_ The app gateway address to verify
    /// @dev Internal function to validate connections
    function _verifyConnections(
        uint32 chainSlug_,
        address target_,
        address appGateway_
    ) internal view {
        (address appGateway, ) = getPlugConfigs(chainSlug_, target_);
        require(appGateway == appGateway_, "Invalid connection");
    }

    /// @notice Encodes a unique payload ID from chain slug, plug address, and counter
    /// @param chainSlug_ The identifier of the chain
    /// @param plug_ The plug address
    /// @param counter_ The current counter value
    /// @return The encoded payload ID as bytes32
    /// @dev Reverts if chainSlug is 0
    function encodePayloadId(
        uint32 chainSlug_,
        address plug_,
        uint256 counter_
    ) internal pure returns (bytes32) {
        if (chainSlug_ == 0) revert InvalidChainSlug();

        // Encode payload ID by bit-shifting and combining:
        // chainSlug (32 bits) | plug address (160 bits) | counter (64 bits)
        return
            bytes32(
                (uint256(chainSlug_) << 224) |
                    (uint256(uint160(plug_)) << 64) |
                    counter_
            );
    }
}
