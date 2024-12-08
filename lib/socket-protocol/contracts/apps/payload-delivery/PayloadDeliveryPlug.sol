// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";
import {ISocket} from "../../interfaces/ISocket.sol";
import {IPlug} from "../../interfaces/IPlug.sol";
import {Ownable} from "../../utils/Ownable.sol";
import {ContractFactory} from "./ContractFactory.sol";
import {FeesManager} from "./FeesManager.sol";
import {PlugBase} from "../../base/PlugBase.sol";
import {FORWARD_CALL, DISTRIBUTE_FEE, DEPLOY, ETH_ADDRESS, WITHDRAW} from "../../common/Constants.sol";
import {InvalidFunction} from "../../common/Errors.sol";
import "../../utils/Ownable.sol";

/// @title PayloadDeliveryPlug
/// @notice Contract for handling payload delivery
contract PayloadDeliveryPlug is
    ContractFactory,
    FeesManager,
    PlugBase,
    Ownable
{
    /// @notice Constructor for PayloadDeliveryPlug
    /// @param socket_ The socket address
    /// @param chainSlug_ The chain slug
    /// @param owner_ The owner address
    constructor(
        address socket_,
        uint32 chainSlug_,
        address owner_
    ) FeesManager() PlugBase(socket_, chainSlug_) Ownable(owner_) {}

    /// @notice Inbound function for handling payloads
    /// @param payload_ The payload
    /// @return bytes memory The encoded return data
    function inbound(
        bytes calldata payload_
    ) external payable override onlySocket returns (bytes memory) {
        (bytes32 actionType, bytes memory data) = abi.decode(
            payload_,
            (bytes32, bytes)
        );

        if (actionType == FORWARD_CALL) {
            return _handleForwardCall(data);
        } else if (actionType == DEPLOY) {
            return _handleDeploy(data);
        } else if (actionType == DISTRIBUTE_FEE) {
            return _handleDistributeFee(data);
        } else if (actionType == WITHDRAW) {
            return _handleWithdraw(data);
        }
        revert InvalidFunction();
    }

    /// @notice Connects the plug to the app gateway and switchboard
    /// @param appGateway_ The app gateway address
    /// @param switchboard_ The switchboard address
    function connect(
        address appGateway_,
        address switchboard_
    ) external onlyOwner {
        _connectSocket(appGateway_, switchboard_);
    }

    /// @notice Handles the forward call
    /// @param data The data
    /// @return bytes memory The encoded return data
    function _handleForwardCall(
        bytes memory data
    ) internal returns (bytes memory) {
        (address target, bytes memory forwardPayload) = abi.decode(
            data,
            (address, bytes)
        );
        (bool success, ) = target.call(forwardPayload);
        require(success, "PayloadDeliveryPlug: call failed");
        return bytes("");
    }
}
