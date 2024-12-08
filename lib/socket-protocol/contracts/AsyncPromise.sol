// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AddressResolverUtil} from "./utils/AddressResolverUtil.sol";

/// @notice The state of the async promise
enum AsyncPromiseState {
    WAITING_FOR_SET_CALLBACK_SELECTOR,
    WAITING_FOR_CALLBACK_EXECUTION,
    RESOLVED
}

/// @title AsyncPromise
/// @notice this contract stores the callback address and data to be executed once the previous call is executed
/// This promise expires once the callback is executed
contract AsyncPromise is AddressResolverUtil {
    /// @notice The callback data to be used when the promise is resolved.
    bytes public callbackData;

    /// @notice The callback selector to be called on the invoker.
    bytes4 public callbackSelector;

    /// @notice The local contract which initiated the async call.
    /// @dev The callback will be executed on this address
    address public immutable localInvoker;

    /// @notice The forwarder address which can call the callback
    address public immutable forwarder;

    /// @notice Indicates whether the promise has been resolved.
    bool public resolved = false;

    /// @notice Error thrown when attempting to resolve an already resolved promise.
    error PromiseAlreadyResolved();

    /// @notice The current state of the async promise.
    AsyncPromiseState public state =
        AsyncPromiseState.WAITING_FOR_SET_CALLBACK_SELECTOR;

    /// @notice Constructor to initialize the AsyncPromise contract.
    /// @param _invoker The address of the local invoker.
    /// @param _forwarder The address of the forwarder.
    /// @param addressResolver_ The address resolver contract address.
    constructor(
        address _invoker,
        address _forwarder,
        address addressResolver_
    ) AddressResolverUtil(addressResolver_) {
        localInvoker = _invoker;
        forwarder = _forwarder;
    }

    /// @notice Marks the promise as resolved and executes the callback if set.
    /// @param returnData The data returned from the async payload execution.
    /// @dev Only callable by the watcher precompile.
    function markResolved(
        bytes memory returnData
    ) external onlyWatcherPrecompile {
        if (resolved) revert PromiseAlreadyResolved();
        resolved = true;
        state = AsyncPromiseState.RESOLVED;

        // Call callback to app gateway
        if (callbackSelector != bytes4(0)) {
            bytes memory combinedCalldata = abi.encodePacked(
                callbackSelector,
                abi.encode(callbackData, returnData)
            );

            (bool success, ) = localInvoker.call(combinedCalldata);
            require(success, "Relaying async call failed");
        }
    }

    /// @notice Sets the callback selector and data for the promise.
    /// @param selector The function selector for the callback.
    /// @param data The data to be passed to the callback.
    /// @return promise_ The address of the current promise.
    function then(
        bytes4 selector,
        bytes memory data
    ) external returns (address promise_) {
        require(
            msg.sender == forwarder || msg.sender == localInvoker,
            "Only the forwarder or local invoker can set this promise's callback"
        );

        if (state == AsyncPromiseState.WAITING_FOR_CALLBACK_EXECUTION) {
            revert("Promise already setup");
        }

        if (state == AsyncPromiseState.WAITING_FOR_SET_CALLBACK_SELECTOR) {
            callbackSelector = selector;
            callbackData = data;
            state = AsyncPromiseState.WAITING_FOR_CALLBACK_EXECUTION;
        }

        promise_ = address(this);
    }
}
