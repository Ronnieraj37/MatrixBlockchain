// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../interfaces/IWatcherPrecompile.sol";
import {Ownable} from "../utils/Ownable.sol";

/// @title WatcherPrecompileConfig
/// @notice Configuration contract for the Watcher Precompile system
/// @dev Handles the mapping between networks, plugs, and app gateways for payload execution
abstract contract WatcherPrecompileConfig is Ownable, IWatcherPrecompile {
    /// @notice Maps network and plug to their configuration
    /// @dev chainSlug => plug => PlugConfig
    mapping(uint32 => mapping(address => PlugConfig)) internal _plugConfigs;

    /// @notice Maps app gateway to their associated plugs per network
    /// @dev appGateway => chainSlug => plug
    mapping(address => mapping(uint32 => address)) public appGatewayPlugs;

    /// @notice Emitted when a new plug is configured for an app gateway
    /// @param appGateway The address of the app gateway
    /// @param chainSlug The identifier of the destination network
    /// @param plug The address of the plug
    event PlugAdded(address appGateway, uint32 chainSlug, address plug);

    /// @notice Configures app gateways with their respective plugs and switchboards
    /// @param configs Array of configurations containing app gateway, network, plug, and switchboard details
    /// @dev Only callable by the contract owner
    /// @dev This helps in verifying that plugs are called by respective app gateways
    function setAppGateways(
        AppGatewayConfig[] calldata configs
    ) external onlyOwner {
        for (uint256 i = 0; i < configs.length; i++) {
            // Store the plug configuration for this network and plug
            _plugConfigs[configs[i].chainSlug][configs[i].plug] = PlugConfig({
                appGateway: configs[i].appGateway,
                switchboard: configs[i].switchboard
            });

            // Create reverse mapping from app gateway to plug for easy lookup
            appGatewayPlugs[configs[i].appGateway][
                configs[i].chainSlug
            ] = configs[i].plug;

            emit PlugAdded(
                configs[i].appGateway,
                configs[i].chainSlug,
                configs[i].plug
            );
        }
    }

    /// @notice Retrieves the configuration for a specific plug on a network
    /// @param chainSlug_ The identifier of the network
    /// @param plug_ The address of the plug
    /// @return The app gateway address and switchboard address for the plug
    /// @dev Returns zero addresses if configuration doesn't exist
    function getPlugConfigs(
        uint32 chainSlug_,
        address plug_
    ) public view returns (address, address) {
        return (
            _plugConfigs[chainSlug_][plug_].appGateway,
            _plugConfigs[chainSlug_][plug_].switchboard
        );
    }
}
