// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "forge-std/Test.sol";
import "../contracts/apps/payload-delivery/PayloadDeliveryPlug.sol";
import {SuperToken} from "../contracts/apps/super-token/SuperToken.sol";
import {LimitHook} from "../contracts/apps/super-token/LimitHook.sol";
import "../contracts/common/Structs.sol";
import "../contracts/common/Constants.sol";

contract PayloadDeliveryTest is Test {
    uint public c;
    address owner = address(uint160(c++));
    uint32 arbChainSlug = 421614;
    uint32 optChainSlug = 11155420;
    address socket;
    PayloadDeliveryPlug payloadDeliveryPlug;

    function setUp() public {
        // core
        socket = address(uint160(c++));
        payloadDeliveryPlug = new PayloadDeliveryPlug(
            socket,
            arbChainSlug,
            owner
        );
    }

    function testDeployAndInitialize() public {
        // Deploy token
        address deployedToken = deployContract(
            abi.encodePacked(
                type(SuperToken).creationCode,
                abi.encode("TestToken", "TT", 18, owner, 10000 ether)
            )
        );
        assertGt(
            deployedToken.code.length,
            0,
            "Deployed token code length is 0"
        );
        assertEq(
            address(payloadDeliveryPlug),
            SuperToken(deployedToken).owner(),
            "Owner should be set to payloadDeliveryPlug"
        );
        // Deploy limitHook
        address deployedLimitHook = deployContract(
            abi.encodePacked(
                type(LimitHook).creationCode,
                abi.encode(100 ether, 100 ether)
            )
        );

        forwardCall(
            deployedToken,
            abi.encodeWithSignature("setLimitHook(address)", deployedLimitHook)
        );
        assertEq(
            deployedLimitHook,
            address(SuperToken(deployedToken).limitHook()),
            "LimitHook should be set"
        );
    }

    function deployContract(
        bytes memory creationCode
    ) internal returns (address) {
        bytes memory payload = abi.encode(
            DEPLOY,
            abi.encode(creationCode, c++)
        );
        vm.prank(socket);
        bytes memory result = payloadDeliveryPlug.inbound(payload);

        address deployedAddress = abi.decode(result, (address));
        require(deployedAddress != address(0), "Deployed address is zero");
        return deployedAddress;
    }

    function forwardCall(address target, bytes memory callData) internal {
        bytes memory payload = abi.encode(
            FORWARD_CALL,
            abi.encode(target, callData)
        );
        vm.prank(socket);
        payloadDeliveryPlug.inbound(payload);
    }

    function testDistributeFee() public {
        address token = ETH_ADDRESS;
        uint256 depositAmount = 1 ether;
        uint256 feeAmount = 0.01 ether;
        address appGateway_ = address(uint160(c++));
        address transmitter = address(uint160(c++));
        payloadDeliveryPlug.deposit{value: depositAmount}(
            token,
            depositAmount,
            appGateway_
        );
        assertEq(
            depositAmount,
            payloadDeliveryPlug.balanceOf(appGateway_, token),
            "Balance should be correct"
        );

        FeesData memory feesData = FeesData({
            feePoolToken: token,
            feePoolChain: arbChainSlug,
            maxFees: 0.01 ether
        });
        Bid memory winningBid = Bid({fee: feeAmount, transmitter: transmitter});
        bytes memory payload = abi.encode(
            DISTRIBUTE_FEE,
            abi.encode(
                appGateway_,
                feesData.feePoolToken,
                winningBid.fee,
                winningBid.transmitter,
                0
            )
        );
        vm.prank(socket);
        payloadDeliveryPlug.inbound(payload);
        assertEq(
            depositAmount - feeAmount,
            payloadDeliveryPlug.balanceOf(appGateway_, token),
            "Fees Balance should be correct"
        );

        assertEq(
            winningBid.fee,
            transmitter.balance,
            "Transmitter Balance should be correct"
        );
    }

    function testWithdrawFeeTokens() public {
        address token = ETH_ADDRESS;
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 0.1 ether;
        address appGateway_ = address(uint160(c++));
        address receiver = address(uint160(c++));
        payloadDeliveryPlug.deposit{value: depositAmount}(
            token,
            depositAmount,
            appGateway_
        );
        assertEq(
            depositAmount,
            payloadDeliveryPlug.balanceOf(appGateway_, token),
            "Balance should be correct"
        );
        bytes memory payload = abi.encode(
            WITHDRAW,
            abi.encode(appGateway_, token, withdrawAmount, receiver)
        );
        vm.prank(socket);
        payloadDeliveryPlug.inbound(payload);
        assertEq(
            depositAmount - withdrawAmount,
            payloadDeliveryPlug.balanceOf(appGateway_, token),
            "Fees Balance should be correct"
        );

        assertEq(
            withdrawAmount,
            receiver.balance,
            "Receiver Balance should be correct"
        );
    }
}
