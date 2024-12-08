// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "../interfaces/ISocket.sol";
import "../interfaces/ISwitchboard.sol";
import "../utils/Ownable.sol";
import "../libraries/RescueFundsLib.sol";
import {ExecutePayloadParams} from "../common/Structs.sol";

/**
 * @title SocketBatcher
 * @notice The SocketBatcher contract is responsible for batching payloads and transmitting them to the destination chain
 */
contract SocketBatcher is Ownable {
    // socket contract
    ISocket public immutable socket__;

    /**
     * @notice Initializes the TransmitManager contract
     * @param socket_ The address of socket contract
     * @param owner_ The owner of the contract with GOVERNANCE_ROLE
     */
    constructor(address owner_, ISocket socket_) Ownable(owner_) {
        socket__ = socket_;
    }

    function attestAndExecute(
        ExecutePayloadParams calldata params
    ) external returns (bytes memory) {
        ISwitchboard(params.switchboard).attest(
            params.payloadId,
            params.root,
            params.watcherSignature
        );
        return
            socket__.execute(
                params.payloadId,
                params.appGateway,
                params.executionGasLimit,
                params.transmitterSignature,
                params.payload
            );
    }

    function rescueFunds(
        address token_,
        address to_,
        uint256 amount_
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, to_, amount_);
    }
}
