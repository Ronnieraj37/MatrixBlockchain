// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../contracts/apps/payload-delivery/app-gateway/AuctionHouse.sol";
import "../contracts/Forwarder.sol";
import "../contracts/interfaces/IAppDeployer.sol";

import "./SetupTest.sol";

contract AuctionHouseTest is SetupTest {
    uint256 public maxFees = 0.0001 ether;
    uint256 public bidAmount = maxFees / 100;
    uint256 public deployCounter;
    uint256 public asyncPromiseCounterLocal = 0;

    AuctionHouse auctionHouse;
    uint256 public asyncCounterTest;

    event PayloadSubmitted(
        bytes32 indexed asyncId,
        address indexed appGateway,
        PayloadDetails[] payloads,
        FeesData feesData,
        uint256 auctionEndDelay
    );
    event BidPlaced(bytes32 indexed asyncId, Bid bid);
    event AuctionEnded(bytes32 indexed asyncId, Bid winningBid);

    function setUpAuctionHouse() internal {
        // core
        deployOffChainVMCore();
        auctionHouse = new AuctionHouse(
            address(addressResolver),
            signatureVerifier
        );

        hoax(watcherEOA);
        addressResolver.setAuctionHouse(address(auctionHouse));

        // chain core contracts
        arbConfig = deploySocket(arbChainSlug);
        arbConfig.payloadDeliveryPlug = new PayloadDeliveryPlug(
            address(arbConfig.socket),
            arbChainSlug,
            owner
        );

        optConfig = deploySocket(optChainSlug);
        optConfig.payloadDeliveryPlug = new PayloadDeliveryPlug(
            address(optConfig.socket),
            optChainSlug,
            owner
        );

        vm.startPrank(owner);
        arbConfig.payloadDeliveryPlug.connect(
            address(auctionHouse),
            address(arbConfig.switchboard)
        );
        optConfig.payloadDeliveryPlug.connect(
            address(auctionHouse),
            address(optConfig.switchboard)
        );
        vm.stopPrank();

        connectAuctionHouse();
    }

    function connectAuctionHouse() internal {
        IWatcherPrecompile.AppGatewayConfig[] memory gateways = new IWatcherPrecompile.AppGatewayConfig[](2);
        gateways[0] = IWatcherPrecompile.AppGatewayConfig({
            plug: address(arbConfig.payloadDeliveryPlug),
            chainSlug: arbChainSlug,
            appGateway: address(auctionHouse),
            switchboard: address(arbConfig.switchboard)
        });
        gateways[1] = IWatcherPrecompile.AppGatewayConfig({
            plug: address(optConfig.payloadDeliveryPlug),
            chainSlug: optChainSlug,
            appGateway: address(auctionHouse),
            switchboard: address(optConfig.switchboard)
        });

        hoax(watcherEOA);
        watcherPrecompile.setAppGateways(gateways);
    }

    //// BATCH DEPLOY AND EXECUTE HELPERS ////
    function getPayloadDeliveryPlug(
        uint32 chainSlug_
    ) internal view returns (address) {
        return address(getSocketConfig(chainSlug_).payloadDeliveryPlug);
    }

    function checkPayloadBatchAndDetails(
        PayloadDetails[] memory payloadDetails,
        bytes32 asyncId,
        address appGateway_,
        uint256 maxFees_
    ) internal view {
        for (uint i = 0; i < payloadDetails.length; i++) {
            PayloadDetails memory payloadDetail = auctionHouse
                .getPayloadDetails(asyncId, i);

            assertEq(
                payloadDetail.chainSlug,
                payloadDetails[i].chainSlug,
                "ChainSlug mismatch"
            );
            assertEq(
                payloadDetail.target,
                payloadDetails[i].target,
                "Target mismatch"
            );
            assertEq(
                keccak256(payloadDetail.payload),
                keccak256(payloadDetails[i].payload),
                "Payload mismatch"
            );
            assertEq(
                uint(payloadDetail.callType),
                uint(payloadDetails[i].callType),
                "CallType mismatch"
            );
            assertEq(
                payloadDetail.executionGasLimit,
                payloadDetails[i].executionGasLimit,
                "ExecutionGasLimit mismatch"
            );
            for (uint j = 0; j < payloadDetail.next.length; j++) {
                assertEq(
                    payloadDetail.next[j],
                    payloadDetails[i].next[j],
                    "Next address mismatch"
                );
            }
        }

        (
            address appGateway,
            FeesData memory feesData,
            uint256 currentPayloadIndex,
            uint256 auctionEndDelayMS,
            bool isBatchCancelled
        ) = auctionHouse.payloadBatches(asyncId);
        assertEq(appGateway_, appGateway, "AppGateway mismatch");
        assertEq(currentPayloadIndex, 0, "CurrentPayloadIndex mismatch");
        assertEq(feesData.maxFees, maxFees_, "MaxFees mismatch");
        assertEq(auctionEndDelayMS, 0, "AuctionEndDelayMS mismatch");
        assertEq(isBatchCancelled, false, "IsBatchCancelled mismatch");
    }

    function bidAndValidate(
        uint256 maxFees_,
        bytes32 asyncId,
        address appDeployer_,
        PayloadDetails[] memory payloadDetails_
    ) internal {
        checkPayloadBatchAndDetails(
            payloadDetails_,
            asyncId,
            appDeployer_,
            maxFees_
        );
        placeBid(asyncId);
        endAuction(asyncId);
    }

    function bidAndExecute(
        bytes32[] memory payloadIds,
        uint256 maxFees_,
        bytes32 asyncId_,
        address appDeployer_,
        PayloadDetails[] memory payloadDetails_
    ) internal {
        bidAndValidate(maxFees_, asyncId_, appDeployer_, payloadDetails_);
        for (uint i = 0; i < payloadIds.length; i++) {
            finalizeAndExecute(
                asyncId_,
                payloadIds[i],
                false,
                payloadDetails_[i]
            );
        }
    }

    function _deploy(
        bytes32[] memory payloadIds,
        uint32 chainSlug_,
        uint256 maxFees_,
        IAppDeployer appDeployer_,
        PayloadDetails[] memory payloadDetails_
    ) internal {
        bytes32 asyncId = getCurrentAsyncId();
        asyncCounterTest++;

        appDeployer_.deployContracts(chainSlug_);
        bidAndExecute(
            payloadIds,
            maxFees_,
            asyncId,
            address(appDeployer_),
            payloadDetails_
        );
    }

    function _configure(
        bytes32[] memory payloadIds,
        address appDeployer_,
        uint256 maxFees_,
        PayloadDetails[] memory payloadDetails_
    ) internal {
        bytes32 asyncId = getCurrentAsyncId();
        asyncCounterTest++;

        bidAndExecute(
            payloadIds,
            maxFees_,
            asyncId,
            appDeployer_,
            payloadDetails_
        );
    }

    function createDeployPayloadDetail(
        uint32 chainSlug_,
        address appDeployer_,
        bytes memory bytecode_
    ) internal returns (PayloadDetails memory payloadDetails) {
        bytes32 salt = keccak256(
            abi.encode(appDeployer_, chainSlug_, deployCounter++)
        );
        bytes memory payload = abi.encode(bytecode_, salt);

        address asyncPromise = predictAsyncPromiseAddress(
            address(auctionHouse),
            address(auctionHouse)
        );
        address[] memory next = new address[](2);
        next[0] = asyncPromise;

        payloadDetails = createPayloadDetails(
            chainSlug_,
            address(0),
            payload,
            CallType.DEPLOY,
            1_000_000_0,
            next
        );

        SocketContracts memory socketConfig = getSocketConfig(chainSlug_);
        payloadDetails.target = address(socketConfig.payloadDeliveryPlug);
        payloadDetails.payload = abi.encode(DEPLOY, payloadDetails.payload);
    }

    function createPayloadDetails(
        uint32 chainSlug_,
        address target_,
        bytes memory payload_,
        CallType callType_,
        uint256 executionGasLimit_,
        address[] memory next_
    ) internal pure returns (PayloadDetails memory) {
        return
            PayloadDetails({
                chainSlug: chainSlug_,
                target: target_,
                payload: payload_,
                callType: callType_,
                executionGasLimit: executionGasLimit_,
                next: next_
            });
    }

    //// AUCTION RELATED FUNCTIONS ////
    function placeBid(bytes32 asyncId) internal {
        vm.expectEmit(true, true, false, false);
        emit BidPlaced(
            asyncId,
            Bid({fee: bidAmount, transmitter: transmitter})
        );
        vm.prank(transmitter);
        bytes memory transmitterSignature = _createSignature(
            keccak256(abi.encode(address(auctionHouse), asyncId, bidAmount)),
            transmitterPrivateKey
        );
        auctionHouse.bid(asyncId, bidAmount, transmitterSignature);
    }

    function endAuction(bytes32 asyncId) internal {
        vm.expectEmit(true, false, false, true);
        emit AuctionEnded(
            asyncId,
            Bid({fee: bidAmount, transmitter: transmitter})
        );

        hoax(watcherEOA);
        watcherPrecompile.resolveTimeout(
            address(auctionHouse),
            abi.encodeWithSelector(AuctionHouse.endAuction.selector, asyncId),
            0
        );
    }

    function finalize(
        bytes32,
        bytes32 payloadId,
        PayloadDetails memory payloadDetails
    ) internal view returns (bytes memory, bytes32) {
        SocketContracts memory socketConfig = getSocketConfig(
            payloadDetails.chainSlug
        );
        PayloadRootParams memory rootParams_ = PayloadRootParams(
            payloadId,
            address(auctionHouse),
            transmitter,
            payloadDetails.executionGasLimit,
            payloadDetails.payload
        );
        bytes32 root = watcherPrecompile.getRoot(rootParams_);

        bytes32 digest = keccak256(
            abi.encode(address(socketConfig.switchboard), root)
        );
        bytes memory watcherSig = _createSignature(digest, watcherPrivateKey);
        return (watcherSig, root);
    }

    function createWithdrawPayloadDetail(
        uint32 chainSlug_,
        address target_,
        address appGateway_,
        address forwarder_,
        bytes memory payload_
    ) internal returns (PayloadDetails memory) {
        return
            createWritePayloadDetail(
                chainSlug_,
                target_,
                appGateway_,
                forwarder_,
                WITHDRAW,
                payload_
            );
    }

    function createExecutePayloadDetail(
        uint32 chainSlug_,
        address target_,
        address appGateway_,
        address forwarder_,
        bytes memory payload_
    ) internal returns (PayloadDetails memory) {
        return
            createWritePayloadDetail(
                chainSlug_,
                target_,
                appGateway_,
                forwarder_,
                FORWARD_CALL,
                payload_
            );
    }

    function createWritePayloadDetail(
        uint32 chainSlug_,
        address target_,
        address appGateway_,
        address forwarder_,
        bytes32 callType_,
        bytes memory payload_
    ) internal returns (PayloadDetails memory payloadDetails) {
        bytes memory payload = abi.encode(
            callType_,
            abi.encode(target_, payload_)
        );

        address asyncPromise = predictAsyncPromiseAddress(
            appGateway_,
            forwarder_
        );
        address[] memory next = new address[](2);
        next[0] = asyncPromise;

        payloadDetails = createPayloadDetails(
            chainSlug_,
            target_,
            payload,
            CallType.WRITE,
            CONFIGURE_GAS_LIMIT,
            next
        );

        SocketContracts memory socketConfig = getSocketConfig(chainSlug_);
        payloadDetails.target = address(socketConfig.payloadDeliveryPlug);
    }

    function createReadPayloadDetail(
        uint32 chainSlug_,
        address target_,
        address appGateway_,
        address forwarder_,
        bytes memory payload_
    ) internal returns (PayloadDetails memory) {
        address asyncPromise = predictAsyncPromiseAddress(
            appGateway_,
            forwarder_
        );
        address[] memory next = new address[](2);
        next[0] = asyncPromise;

        return
            createPayloadDetails(
                chainSlug_,
                target_,
                payload_,
                CallType.READ,
                CONFIGURE_GAS_LIMIT,
                next
            );
    }

    function finalizeQuery(
        bytes32 payloadId,
        bytes memory returnData_
    ) internal {
        resolvePromise(payloadId, returnData_);
    }

    function finalizeAndExecute(
        bytes32 asyncId,
        bytes32 payloadId,
        bool isWithdraw,
        PayloadDetails memory payloadDetails
    ) internal {
        (bytes memory watcherSig, bytes32 root) = finalize(
            asyncId,
            payloadId,
            payloadDetails
        );
        bytes memory returnData = relayTx(
            payloadDetails.chainSlug,
            payloadId,
            root,
            address(auctionHouse),
            payloadDetails,
            watcherSig
        );

        if (!isWithdraw) {
            resolvePromise(payloadId, returnData);
        }
    }

    function predictAsyncPromiseAddress(
        address invoker_,
        address forwarder_
    ) internal returns (address) {
        bytes memory constructorArgs = abi.encode(
            invoker_,
            forwarder_,
            address(addressResolver)
        );
        bytes memory combinedBytecode = abi.encodePacked(
            asyncPromiseBytecode,
            constructorArgs
        );

        bytes32 salt = keccak256(
            abi.encodePacked(constructorArgs, asyncPromiseCounterLocal++)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(addressResolver),
                salt,
                keccak256(combinedBytecode)
            )
        );

        return address(uint160(uint256(hash)));
    }

    function getCurrentAsyncId() public view returns (bytes32) {
        return
            bytes32(
                (uint256(uint160(address(auctionHouse))) << 64) |
                    asyncCounterTest
            );
    }
}
