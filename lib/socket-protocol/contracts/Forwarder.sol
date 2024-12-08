// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IAddressResolver.sol";
import "./interfaces/IAuctionHouse.sol";
import "./interfaces/IAppGateway.sol";
import "./interfaces/IPromise.sol";
import "./AsyncPromise.sol";
import "./interfaces/IForwarder.sol";

/// @title Forwarder Contract
/// @notice This contract acts as a forwarder for async calls to the on-chain contracts.
contract Forwarder is IForwarder {
    /// @notice chain id
    uint32 immutable chainSlug;

    /// @notice on-chain address associated with this forwarder
    address immutable onChainAddress;

    /// @notice address resolver contract address for imp addresses
    address immutable addressResolver;

    /// @notice caches the latest async promise address for the last call
    address latestAsyncPromise;

    /// @notice Constructor to initialize the forwarder contract.
    /// @param chainSlug_ chain id
    /// @param onChainAddress_ on-chain address
    /// @param addressResolver_ address resolver contract address
    constructor(
        uint32 chainSlug_,
        address onChainAddress_,
        address addressResolver_
    ) {
        chainSlug = chainSlug_;
        onChainAddress = onChainAddress_;
        addressResolver = addressResolver_;
    }

    /// @notice Returns the on-chain address associated with this forwarder.
    /// @return The on-chain address.
    function getOnChainAddress() external view returns (address) {
        return onChainAddress;
    }

    /// @notice Returns the chain id
    /// @return chain id
    function getChainSlug() external view returns (uint32) {
        return chainSlug;
    }

    /// @notice Stores the callback address and data to be executed once the promise is resolved.
    /// @dev This function should not be called before the fallback function.
    /// @param selector The function selector for callback
    /// @param data The data to be passed to callback
    /// @return promise_ The address of the new promise
    function then(
        bytes4 selector,
        bytes memory data
    ) external returns (address promise_) {
        if (latestAsyncPromise == address(0))
            revert("Forwarder: no async promise found");
        promise_ = IPromise(latestAsyncPromise).then(selector, data);
        latestAsyncPromise = address(0);
    }

    /// @notice Fallback function to process the contract calls to onChainAddress
    /// @dev It queues the calls in the auction house and deploys the promise contract
    fallback() external payable {
        // Retrieve the auction house address from the address resolver.
        address auctionHouse = IAddressResolver(addressResolver).auctionHouse();
        if (auctionHouse == address(0)) {
            revert("Forwarder: auctionHouse not found");
        }

        // Deploy a new async promise contract.
        latestAsyncPromise = IAddressResolver(addressResolver)
            .deployAsyncPromiseContract(msg.sender);

        // Determine if the call is a read or write operation.
        bool isReadCall = IAppGateway(msg.sender).isReadCall();

        // Queue the call in the auction house.
        IAuctionHouse(auctionHouse).queue(
            chainSlug,
            onChainAddress,
            bytes32(uint256(uint160(latestAsyncPromise))),
            isReadCall ? CallType.READ : CallType.WRITE,
            msg.data
        );
    }

    receive() external payable {}
}
