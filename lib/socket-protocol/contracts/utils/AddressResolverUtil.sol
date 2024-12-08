// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../interfaces/IAddressResolver.sol";
import "../interfaces/IAuctionHouse.sol";
import "../interfaces/IWatcherPrecompile.sol";

/// @title AddressResolverUtil
/// @notice Utility contract for resolving system contract addresses
/// @dev Provides access control and address resolution functionality for the system
abstract contract AddressResolverUtil {
    /// @notice The address resolver contract reference
    /// @dev Used to look up system contract addresses
    IAddressResolver public addressResolver;

    /// @notice Initializes the contract with an address resolver
    /// @param _addressResolver The address of the resolver contract
    /// @dev Sets up the initial configuration for address resolution
    constructor(address _addressResolver) {
        addressResolver = IAddressResolver(_addressResolver);
    }

    /// @notice Restricts function access to the auction house contract
    /// @dev Validates that msg.sender matches the registered auction house address
    modifier onlyPayloadDelivery() {
        require(
            msg.sender == addressResolver.auctionHouse(),
            "Only payload delivery"
        );
        _;
    }

    /// @notice Restricts function access to the watcher precompile contract
    /// @dev Validates that msg.sender matches the registered watcher precompile address
    modifier onlyWatcherPrecompile() {
        require(
            msg.sender == address(addressResolver.watcherPrecompile()),
            "Only watcher precompile"
        );
        _;
    }

    /// @notice Gets the auction house contract interface
    /// @return IAuctionHouse interface of the registered auction house
    /// @dev Resolves and returns the auction house contract for interaction
    function auctionHouse() public view returns (IAuctionHouse) {
        return IAuctionHouse(addressResolver.auctionHouse());
    }

    /// @notice Gets the watcher precompile contract interface
    /// @return IWatcherPrecompile interface of the registered watcher precompile
    /// @dev Resolves and returns the watcher precompile contract for interaction
    function watcherPrecompile() public view returns (IWatcherPrecompile) {
        return IWatcherPrecompile(addressResolver.watcherPrecompile());
    }

    /// @notice Updates the address resolver reference
    /// @param _addressResolver New address resolver contract address
    /// @dev Internal function to be called by inheriting contracts
    /// @dev Should be protected with appropriate access control in implementing contracts
    function setAddressResolver(address _addressResolver) internal {
        // Update the address resolver reference
        addressResolver = IAddressResolver(_addressResolver);
    }
}
