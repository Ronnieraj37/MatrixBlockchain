// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SuperTokenDeployer} from "../contracts/apps/super-token/app-gateway/SuperTokenDeployer.sol";
import {SuperTokenApp} from "../contracts/apps/super-token/app-gateway/SuperTokenApp.sol";
import "./AuctionHouse.sol";

contract SuperTokenTest is AuctionHouseTest {
    struct AppContracts {
        SuperTokenApp superTokenApp;
        SuperTokenDeployer superTokenDeployer;
        bytes32 superToken;
        bytes32 limitHook;
    }
    AppContracts appContracts;
    uint256 srcAmount = 0.01 ether;
    SuperTokenApp.UserOrder userOrder;

    event BatchCancelled(bytes32 indexed asyncId);
    event FinalizeRequested(
        bytes32 indexed payloadId,
        AsyncRequest asyncRequest
    );
    event QueryRequested(
        uint32 chainSlug,
        address targetAddress,
        bytes32 payloadId,
        bytes payload
    );

    function setUp() public {
        // core
        setUpAuctionHouse();

        // app specific
        deploySuperTokenApp();
    }

    function deploySuperTokenApp() internal {
        SuperTokenDeployer superTokenDeployer = new SuperTokenDeployer(
            address(addressResolver),
            owner,
            10000000000000000000000,
            10000000000000000000000,
            "SUPER TOKEN",
            "SUPER",
            18,
            owner,
            1000000000 ether,
            createFeesData(maxFees)
        );
        SuperTokenApp superTokenApp = new SuperTokenApp(
            address(addressResolver),
            address(superTokenDeployer),
            createFeesData(maxFees)
        );

        appContracts = AppContracts({
            superTokenApp: superTokenApp,
            superTokenDeployer: superTokenDeployer,
            superToken: superTokenDeployer.superToken(),
            limitHook: superTokenDeployer.limitHook()
        });
    }

    function createDeployPayloadDetailsArray(
        uint32 chainSlug_
    ) internal returns (PayloadDetails[] memory) {
        PayloadDetails[] memory payloadDetails = new PayloadDetails[](2);
        payloadDetails[0] = createDeployPayloadDetail(
            chainSlug_,
            address(appContracts.superTokenDeployer),
            appContracts.superTokenDeployer.creationCodeWithArgs(
                appContracts.superToken
            )
        );
        payloadDetails[1] = createDeployPayloadDetail(
            chainSlug_,
            address(appContracts.superTokenDeployer),
            appContracts.superTokenDeployer.creationCodeWithArgs(
                appContracts.limitHook
            )
        );

        for (uint i = 0; i < payloadDetails.length; i++) {
            payloadDetails[i].next[1] = predictAsyncPromiseAddress(
                address(auctionHouse),
                address(auctionHouse)
            );
        }

        return payloadDetails;
    }

    function createConfigurePayloadDetailsArray(
        uint32 chainSlug_
    ) internal returns (PayloadDetails[] memory) {
        address superTokenForwarder = appContracts
            .superTokenDeployer
            .forwarderAddresses(appContracts.superToken, chainSlug_);
        address limitHookForwarder = appContracts
            .superTokenDeployer
            .forwarderAddresses(appContracts.limitHook, chainSlug_);

        address deployedToken = IForwarder(superTokenForwarder)
            .getOnChainAddress();

        address deployedLimitHook = IForwarder(limitHookForwarder)
            .getOnChainAddress();

        PayloadDetails[] memory payloadDetails = new PayloadDetails[](1);
        payloadDetails[0] = createExecutePayloadDetail(
            chainSlug_,
            deployedToken,
            address(appContracts.superTokenDeployer),
            superTokenForwarder,
            abi.encodeWithSignature("setLimitHook(address)", deployedLimitHook)
        );

        for (uint i = 0; i < payloadDetails.length; i++) {
            payloadDetails[i].next[1] = predictAsyncPromiseAddress(
                address(auctionHouse),
                address(auctionHouse)
            );
        }

        return payloadDetails;
    }

    function createBridgePayloadDetailsArray(
        uint32 srcChainSlug_,
        uint32 dstChainSlug_
    ) internal returns (PayloadDetails[] memory) {
        PayloadDetails[] memory payloadDetails = new PayloadDetails[](4);

        address deployedSrcToken = IForwarder(userOrder.srcToken)
            .getOnChainAddress();
        address deployedDstToken = IForwarder(userOrder.dstToken)
            .getOnChainAddress();

        payloadDetails[0] = createExecutePayloadDetail(
            srcChainSlug_,
            deployedSrcToken,
            address(appContracts.superTokenApp),
            userOrder.srcToken,
            abi.encodeWithSignature(
                "lockTokens(address,uint256)",
                userOrder.user,
                userOrder.srcAmount
            )
        );

        payloadDetails[1] = createReadPayloadDetail(
            srcChainSlug_,
            deployedSrcToken,
            address(appContracts.superTokenApp),
            userOrder.srcToken,
            abi.encodeWithSignature("balanceOf(address)", userOrder.user)
        );

        payloadDetails[2] = createExecutePayloadDetail(
            dstChainSlug_,
            deployedDstToken,
            address(appContracts.superTokenApp),
            userOrder.dstToken,
            abi.encodeWithSignature(
                "mint(address,uint256)",
                userOrder.user,
                userOrder.srcAmount
            )
        );

        payloadDetails[3] = createExecutePayloadDetail(
            srcChainSlug_,
            deployedSrcToken,
            address(appContracts.superTokenApp),
            userOrder.srcToken,
            abi.encodeWithSignature(
                "burn(address,uint256)",
                userOrder.user,
                userOrder.srcAmount
            )
        );

        for (uint i = 0; i < payloadDetails.length; i++) {
            payloadDetails[i].next[1] = predictAsyncPromiseAddress(
                address(auctionHouse),
                address(auctionHouse)
            );
        }

        return payloadDetails;
    }

    function createCancelPayloadDetailsArray(
        uint32 srcChainSlug_
    ) internal returns (PayloadDetails[] memory) {
        PayloadDetails[] memory payloadDetails = new PayloadDetails[](1);

        address deployedSrcToken = IForwarder(userOrder.srcToken)
            .getOnChainAddress();

        payloadDetails[0] = createExecutePayloadDetail(
            srcChainSlug_,
            deployedSrcToken,
            address(appContracts.superTokenApp),
            userOrder.srcToken,
            abi.encodeWithSignature(
                "unlockTokens(address,uint256)",
                userOrder.user,
                userOrder.srcAmount
            )
        );

        payloadDetails[0].next[1] = predictAsyncPromiseAddress(
            address(auctionHouse),
            address(auctionHouse)
        );
        return payloadDetails;
    }

    function testContractDeployment() public {
        bytes32[] memory payloadIds = getWritePayloadIds(
            arbChainSlug,
            getPayloadDeliveryPlug(arbChainSlug),
            2
        );

        PayloadDetails[]
            memory payloadDetails = createDeployPayloadDetailsArray(
                arbChainSlug
            );

        _deploy(
            payloadIds,
            arbChainSlug,
            maxFees,
            appContracts.superTokenDeployer,
            payloadDetails
        );
    }

    function testConfigure() public {
        writePayloadIdCounter = 0;
        bytes32[] memory payloadIds = getWritePayloadIds(
            arbChainSlug,
            getPayloadDeliveryPlug(arbChainSlug),
            2
        );
        PayloadDetails[]
            memory payloadDetails = createDeployPayloadDetailsArray(
                arbChainSlug
            );
        _deploy(
            payloadIds,
            arbChainSlug,
            maxFees,
            appContracts.superTokenDeployer,
            payloadDetails
        );

        payloadIds = getWritePayloadIds(
            arbChainSlug,
            getPayloadDeliveryPlug(arbChainSlug),
            1
        );
        payloadDetails = createConfigurePayloadDetailsArray(arbChainSlug);
        _configure(
            payloadIds,
            address(appContracts.superTokenApp),
            maxFees,
            payloadDetails
        );
    }

    function beforeBridge() internal {
        writePayloadIdCounter = 0;
        bytes32[] memory payloadIds = getWritePayloadIds(
            optChainSlug,
            getPayloadDeliveryPlug(optChainSlug),
            2
        );
        PayloadDetails[]
            memory payloadDetails = createDeployPayloadDetailsArray(
                optChainSlug
            );
        _deploy(
            payloadIds,
            optChainSlug,
            maxFees,
            appContracts.superTokenDeployer,
            payloadDetails
        );

        payloadIds = getWritePayloadIds(
            optChainSlug,
            getPayloadDeliveryPlug(optChainSlug),
            1
        );
        payloadDetails = createConfigurePayloadDetailsArray(optChainSlug);
        _configure(
            payloadIds,
            address(appContracts.superTokenApp),
            maxFees,
            payloadDetails
        );

        payloadIds = getWritePayloadIds(
            arbChainSlug,
            getPayloadDeliveryPlug(arbChainSlug),
            2
        );

        payloadDetails = createDeployPayloadDetailsArray(arbChainSlug);
        _deploy(
            payloadIds,
            arbChainSlug,
            maxFees,
            appContracts.superTokenDeployer,
            payloadDetails
        );

        payloadIds = getWritePayloadIds(
            arbChainSlug,
            getPayloadDeliveryPlug(arbChainSlug),
            1
        );
        payloadDetails = createConfigurePayloadDetailsArray(arbChainSlug);
        _configure(
            payloadIds,
            address(appContracts.superTokenApp),
            maxFees,
            payloadDetails
        );
    }

    function _bridge()
        internal
        returns (bytes32, bytes32[] memory, PayloadDetails[] memory)
    {
        beforeBridge();

        userOrder = SuperTokenApp.UserOrder({
            srcToken: appContracts.superTokenDeployer.forwarderAddresses(
                appContracts.superToken,
                arbChainSlug
            ),
            dstToken: appContracts.superTokenDeployer.forwarderAddresses(
                appContracts.superToken,
                optChainSlug
            ),
            user: owner, // 2 account anvil
            srcAmount: srcAmount, // .01 ETH in wei
            deadline: 1672531199 // Unix timestamp for a future date
        });
        uint32 srcChainSlug = IForwarder(userOrder.srcToken).getChainSlug();
        uint32 dstChainSlug = IForwarder(userOrder.dstToken).getChainSlug();

        bytes32[] memory payloadIds = new bytes32[](4);
        payloadIds[0] = getWritePayloadId(
            srcChainSlug,
            address(getSocketConfig(srcChainSlug).payloadDeliveryPlug),
            writePayloadIdCounter++
        );
        payloadIds[1] = bytes32(readPayloadIdCounter++);
        payloadIds[2] = getWritePayloadId(
            dstChainSlug,
            address(getSocketConfig(dstChainSlug).payloadDeliveryPlug),
            writePayloadIdCounter++
        );
        payloadIds[3] = getWritePayloadId(
            srcChainSlug,
            address(getSocketConfig(srcChainSlug).payloadDeliveryPlug),
            writePayloadIdCounter++
        );
        writePayloadIdCounter++;

        PayloadDetails[]
            memory payloadDetails = createBridgePayloadDetailsArray(
                srcChainSlug,
                dstChainSlug
            );
        bytes32 bridgeAsyncId = getCurrentAsyncId();
        asyncCounterTest++;

        bytes memory encodedOrder = abi.encode(userOrder);
        appContracts.superTokenApp.bridge(encodedOrder);
        bidAndValidate(
            maxFees,
            bridgeAsyncId,
            address(appContracts.superTokenApp),
            payloadDetails
        );
        return (bridgeAsyncId, payloadIds, payloadDetails);
    }

    function testBridge() public {
        (
            bytes32 bridgeAsyncId,
            bytes32[] memory payloadIds,
            PayloadDetails[] memory payloadDetails
        ) = _bridge();

        finalizeAndExecute(
            bridgeAsyncId,
            payloadIds[0],
            false,
            payloadDetails[0]
        );

        vm.expectEmit(true, false, false, false);
        emit FinalizeRequested(
            payloadIds[2],
            AsyncRequest(
                payloadDetails[2].next,
                address(0),
                transmitter,
                payloadDetails[2].executionGasLimit,
                payloadDetails[2].payload,
                address(0),
                bytes32(0)
            )
        );
        finalizeQuery(payloadIds[1], abi.encode(srcAmount));
        finalizeAndExecute(
            bridgeAsyncId,
            payloadIds[2],
            false,
            payloadDetails[2]
        );
        finalizeAndExecute(
            bridgeAsyncId,
            payloadIds[3],
            false,
            payloadDetails[3]
        );
    }

    function testCancel() public {
        (
            bytes32 bridgeAsyncId,
            bytes32[] memory payloadIds,
            PayloadDetails[] memory payloadDetails
        ) = _bridge();

        finalizeAndExecute(
            bridgeAsyncId,
            payloadIds[0],
            false,
            payloadDetails[0]
        );

        vm.expectEmit(true, true, false, true);
        emit BatchCancelled(bridgeAsyncId);
        finalizeQuery(payloadIds[1], abi.encode(0.001 ether));

        bytes32[] memory cancelPayloadIds = new bytes32[](1);
        uint32 srcChainSlug = IForwarder(userOrder.srcToken).getChainSlug();

        cancelPayloadIds[0] = getWritePayloadId(
            srcChainSlug,
            address(getSocketConfig(srcChainSlug).payloadDeliveryPlug),
            writePayloadIdCounter++
        );

        PayloadDetails[]
            memory cancelPayloadDetails = createCancelPayloadDetailsArray(
                srcChainSlug
            );

        bytes32 cancelAsyncId = getCurrentAsyncId();
        asyncCounterTest++;

        bidAndValidate(
            maxFees,
            cancelAsyncId,
            address(appContracts.superTokenApp),
            cancelPayloadDetails
        );
        finalizeAndExecute(
            cancelAsyncId,
            cancelPayloadIds[0],
            false,
            cancelPayloadDetails[0]
        );
    }

    function testWithdrawTo() public {
        uint32 chainSlug = arbChainSlug;
        address token = ETH_ADDRESS;
        uint256 depositAmount = 1 ether;
        uint256 withdrawAmount = 0.1 ether;
        address appGateway = address(appContracts.superTokenApp);
        address receiver = address(uint160(c++));

        SocketContracts memory socketConfig = getSocketConfig(chainSlug);
        socketConfig.payloadDeliveryPlug.deposit{value: depositAmount}(
            token,
            depositAmount,
            appGateway
        );
        assertEq(
            depositAmount,
            socketConfig.payloadDeliveryPlug.balanceOf(appGateway, token),
            "Balance should be correct"
        );

        appContracts.superTokenApp.withdrawFeeTokens(
            chainSlug,
            token,
            withdrawAmount,
            receiver
        );

        bytes32[] memory withdrawPayloadIds = new bytes32[](1);
        withdrawPayloadIds[0] = getWritePayloadId(
            chainSlug,
            address(getSocketConfig(chainSlug).payloadDeliveryPlug),
            writePayloadIdCounter++
        );
        bytes32 withdrawAsyncId = getCurrentAsyncId();
        asyncCounterTest++;

        bytes memory withdrawPayload = abi.encode(
            WITHDRAW,
            abi.encode(appGateway, token, withdrawAmount, receiver)
        );

        PayloadDetails[] memory payloadDetails = new PayloadDetails[](1);
        payloadDetails[0] = PayloadDetails({
            chainSlug: chainSlug,
            target: address(getSocketConfig(chainSlug).payloadDeliveryPlug),
            payload: withdrawPayload,
            callType: CallType.WITHDRAW,
            executionGasLimit: auctionHouse.feeCollectionGasLimit(chainSlug),
            next: new address[](2)
        });

        payloadDetails[0].next[1] = predictAsyncPromiseAddress(
            address(auctionHouse),
            address(auctionHouse)
        );

        bidAndValidate(
            maxFees,
            withdrawAsyncId,
            address(appContracts.superTokenApp),
            payloadDetails
        );
        finalizeAndExecute(
            withdrawAsyncId,
            withdrawPayloadIds[0],
            true,
            payloadDetails[0]
        );
    }
}
