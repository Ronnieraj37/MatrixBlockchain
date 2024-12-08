// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../../../base/AppGatewayBase.sol";
import {ISuperToken} from "../../../interfaces/ISuperToken.sol";
import "../../../utils/Ownable.sol";

contract SuperTokenApp is AppGatewayBase, Ownable {
    uint256 public idCounter;
    event Bridged(bytes32 asyncId);

    struct UserOrder {
        address srcToken;
        address dstToken;
        address user;
        uint256 srcAmount;
        uint256 deadline;
    }

    constructor(
        address _addressResolver,
        address deployerContract_,
        FeesData memory feesData_
    ) AppGatewayBase(_addressResolver) Ownable(msg.sender) {
        addressResolver.setContractsToGateways(deployerContract_);
        _setFeesData(feesData_);
    }

    function checkBalance(
        bytes memory data,
        bytes memory returnData
    ) external onlyPromises {
        (UserOrder memory order, bytes32 asyncId) = abi.decode(
            data,
            (UserOrder, bytes32)
        );

        uint256 balance = abi.decode(returnData, (uint256));
        if (balance < order.srcAmount) {
            _revertTx(asyncId);
            return;
        }
        _unlockTokens(order.srcToken, order.user, order.srcAmount);
    }

    function _unlockTokens(
        address srcToken,
        address user,
        uint256 amount
    ) internal async {
        ISuperToken(srcToken).unlockTokens(user, amount);
    }

    function bridge(
        bytes memory _order
    ) external async returns (bytes32 asyncId) {
        UserOrder memory order = abi.decode(_order, (UserOrder));
        asyncId = _getCurrentAsyncId();
        ISuperToken(order.srcToken).lockTokens(order.user, order.srcAmount);

        _readCallOn();
        // goes to forwarder and deploys promise and stores it
        ISuperToken(order.srcToken).balanceOf(order.user);
        IPromise(order.srcToken).then(
            this.checkBalance.selector,
            abi.encode(order, asyncId)
        );

        _readCallOff();
        ISuperToken(order.dstToken).mint(order.user, order.srcAmount);
        ISuperToken(order.srcToken).burn(order.user, order.srcAmount);

        emit Bridged(asyncId);
    }

    function withdrawFeeTokens(
        uint32 chainSlug_,
        address token_,
        uint256 amount_,
        address receiver_
    ) external onlyOwner {
        _withdrawFeeTokens(chainSlug_, token_, amount_, receiver_);
    }
}
