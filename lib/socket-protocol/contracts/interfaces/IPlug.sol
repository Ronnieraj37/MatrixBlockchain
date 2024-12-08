// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title IPlug
 * @notice Interface for a plug contract that executes the payload received from a source chain.
 */
interface IPlug {
    /**
     * @dev this should be only executable by socket
     * @notice executes the payload received from source chain
     * @notice It is expected to have original sender checks in the destination plugs using payload
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        bytes calldata payload_
    ) external payable returns (bytes memory);
}
