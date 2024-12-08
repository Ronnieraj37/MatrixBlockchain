// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/utils/SafeTransferLib.sol";

import {ETH_ADDRESS} from "../../common/Constants.sol";

/// @title FeesManager
/// @notice Abstract contract for managing fees
abstract contract FeesManager {
    mapping(address => mapping(address => uint256)) public balanceOf;
    mapping(uint256 => bool) public feesRedeemed;

    error FeesAlreadyPaid();

    constructor() {}

    /// @notice Handles the distribution of fees
    /// @param data The data
    /// @return bytes memory The encoded return data
    function _handleDistributeFee(
        bytes memory data
    ) internal returns (bytes memory) {
        (
            address appGateway,
            address feeToken,
            uint256 fee,
            address transmitter,
            uint256 feesCounter
        ) = abi.decode(data, (address, address, uint256, address, uint256));

        if (feesRedeemed[feesCounter]) revert FeesAlreadyPaid();
        feesRedeemed[feesCounter] = true;

        require(
            balanceOf[appGateway][feeToken] >= fee,
            "PayloadDeliveryPlug: insufficient balance"
        );
        balanceOf[appGateway][feeToken] -= fee;
        _transferTokens(feeToken, fee, transmitter);
        return bytes("");
    }

    /// @notice Handles the withdrawal of funds
    /// @param data The data
    /// @return bytes memory The encoded return data
    function _handleWithdraw(
        bytes memory data
    ) internal returns (bytes memory) {
        (
            address appGateway,
            address token,
            uint256 amount,
            address receiver
        ) = abi.decode(data, (address, address, uint256, address));

        require(
            balanceOf[appGateway][token] >= amount,
            "PayloadDeliveryPlug: insufficient balance"
        );
        balanceOf[appGateway][token] -= amount;
        _transferTokens(token, amount, receiver);
        return bytes("");
    }

    /// @notice Deposits funds
    /// @param token The token address
    /// @param amount The amount
    /// @param appGateway_ The app gateway address
    function deposit(
        address token,
        uint256 amount,
        address appGateway_
    ) external payable {
        if (token == ETH_ADDRESS) {
            require(msg.value == amount, "Fees Manager: invalid depositamount");
        } else {
            SafeTransferLib.safeTransferFrom(
                ERC20(token),
                msg.sender,
                address(this),
                amount
            );
        }
        balanceOf[appGateway_][token] += amount;
    }

    /// @notice Transfers tokens
    /// @param token The token address
    /// @param amount The amount
    /// @param receiver The receiver address
    function _transferTokens(
        address token,
        uint256 amount,
        address receiver
    ) internal {
        if (token == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(receiver, amount);
        } else {
            SafeTransferLib.safeTransfer(ERC20(token), receiver, amount);
        }
    }
}
