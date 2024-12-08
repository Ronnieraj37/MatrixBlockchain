// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "./ISocket.sol";

/**
 * @title IHasher
 * @notice Interface for hasher contract that calculates the packed payload
 */
interface IHasher {
    /**
     * @notice returns the bytes32 hash of the payload packed
     */
    function packPayload(
        bytes32 payloadId_,
        address appGateway_,
        address transmitter_,
        uint256 executionGasLimit_,
        bytes memory payload_
    ) external returns (bytes32);
}
