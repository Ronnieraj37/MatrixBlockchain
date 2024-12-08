// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "../../interfaces/IHasher.sol";
import "../../interfaces/ISocket.sol";
import "../../libraries/RescueFundsLib.sol";

import "./AccessControl.sol";
import {RESCUE_ROLE} from "./AccessRoles.sol";

/**
 * @title Hasher
 * @notice contract for hasher contract that calculates the packed payload
 * @dev This contract is modular component in socket to support different payload packing algorithms in case of blockchains
 * not supporting this type of packing.
 */
contract Hasher is IHasher, AccessControl {
    /**
     * @notice initializes and grants RESCUE_ROLE to owner.
     * @param owner_ The address of the owner of the contract.
     */
    constructor(address owner_) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    /// @inheritdoc IHasher
    function packPayload(
        bytes32 payloadId_,
        address appGateway_,
        address transmitter_,
        uint256 executionGasLimit_,
        bytes memory payload_
    ) external pure override returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    payloadId_,
                    appGateway_,
                    transmitter_,
                    executionGasLimit_,
                    payload_
                )
            );
    }

    /**
     * @notice Rescues funds from the contract if they are locked by mistake.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}
