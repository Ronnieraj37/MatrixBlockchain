// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

/**
 * @title ISwitchboard
 * @dev The interface for a switchboard contract that is responsible for verification of packets between
 * different blockchain networks.
 */
interface ISwitchboard {
    /**
     * @notice Checks if a packet can be allowed to go through the switchboard.
     * @param root the packet root.
     * @param packetId The unique identifier for the packet.
     * @return A boolean indicating whether the packet is allowed to go through the switchboard or not.
     */
    function allowPacket(
        bytes32 root,
        bytes32 packetId
    ) external view returns (bool);

    function attest(
        bytes32 payloadId_,
        bytes32 root_,
        bytes calldata signature_
    ) external;
}
