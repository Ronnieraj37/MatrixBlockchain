// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ISocket} from "../interfaces/ISocket.sol";
import {IPlug} from "../interfaces/IPlug.sol";
import {NotSocket} from "../common/Errors.sol";

/// @title PlugBase
/// @notice Abstract contract for plugs
abstract contract PlugBase is IPlug {
    ISocket public socket__;
    uint32 public chainSlug;

    event ConnectorPlugDisconnected();

    /// @notice Constructor for PlugBase
    /// @param socket_ The socket address
    /// @param chainSlug_ The chain slug
    constructor(address socket_, uint32 chainSlug_) {
        socket__ = ISocket(socket_);
        chainSlug = chainSlug_;
    }

    /// @notice Modifier to ensure only the socket can call the function
    /// @dev only the socket can call the function
    modifier onlySocket() {
        if (msg.sender != address(socket__)) revert NotSocket();
        _;
    }

    /// @notice Inbound function for handling incoming messages
    /// @param payload_ The payload
    /// @return bytes memory The encoded return data
    function inbound(
        bytes calldata payload_
    ) external payable virtual returns (bytes memory) {}

    /// @notice Connects the plug to the app gateway and switchboard
    /// @param appGateway_ The app gateway address
    /// @param switchboard_ The switchboard address
    function _connectSocket(
        address appGateway_,
        address switchboard_
    ) internal {
        socket__.connect(appGateway_, switchboard_);
    }

    /// @notice Disconnects the plug from the socket
    function disconnect() internal {
        (, address switchboard) = socket__.getPlugConfig(address(this));
        socket__.connect(address(0), switchboard);
        emit ConnectorPlugDisconnected();
    }

    /// @notice Sets the socket
    /// @param socket_ The socket address
    function setSocket(address socket_) internal {
        socket__ = ISocket(socket_);
    }
}
