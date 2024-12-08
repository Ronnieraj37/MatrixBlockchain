// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./QueueAsync.sol";

import {IAuctionHouse} from "../../../interfaces/IAuctionHouse.sol";
import {IAppGateway} from "../../../interfaces/IAppGateway.sol";
import {IAddressResolver} from "../../../interfaces/IAddressResolver.sol";
import {Bid, PayloadBatch, FeesData, PayloadDetails} from "../../../common/Structs.sol";
import {FORWARD_CALL, DISTRIBUTE_FEE, DEPLOY, WITHDRAW} from "../../../common/Constants.sol";

/// @title BatchAsync
/// @notice Abstract contract for managing asynchronous payload batches
abstract contract BatchAsync is QueueAsync {
    uint256 public asyncCounter;

    // asyncId => PayloadBatch
    mapping(bytes32 => PayloadBatch) public payloadBatches;
    // asyncId => totalPayloadsRemaining
    mapping(bytes32 => uint256) public totalPayloadsRemaining;
    // asyncId => PayloadDetails[]
    mapping(bytes32 => PayloadDetails[]) public payloadDetailsArrays;

    error AllPayloadsExecuted();
    error NotFromForwarder();
    error CallFailed(bytes32 payloadId);
    error DelayLimitReached();
    error PayloadTooLarge();
    event PayloadSubmitted(
        bytes32 indexed asyncId,
        address indexed appGateway,
        PayloadDetails[] payloads,
        FeesData feesData,
        uint256 auctionEndDelay
    );

    event PayloadAsyncRequested(
        bytes32 indexed asyncId,
        bytes32 indexed payloadId,
        bytes32 indexed root,
        PayloadDetails payloadDetails
    );
    event BatchCancelled(bytes32 indexed asyncId);

    /// @notice Initiates a batch of payloads
    /// @param feesData_ The fees data
    /// @param auctionEndDelayMS_ The auction end delay in milliseconds
    /// @return asyncId The ID of the batch
    function batch(
        FeesData memory feesData_,
        uint256 auctionEndDelayMS_
    ) external returns (bytes32) {
        if (auctionEndDelayMS_ > 10 * 60 * 1000) revert DelayLimitReached();
        PayloadDetails[]
            memory payloadDetailsArray = createPayloadDetailsArray();

        return
            deliverPayload(payloadDetailsArray, feesData_, auctionEndDelayMS_);
    }

    /// @notice Callback function for handling promises
    /// @param asyncId_ The ID of the batch
    /// @param payloadDetails_ The payload details
    function callback(
        bytes memory asyncId_,
        bytes memory payloadDetails_
    ) external virtual onlyPromises {}

    /// @notice Delivers a payload batch
    /// @param payloadDetails_ The payload details
    /// @param feesData_ The fees data
    /// @param auctionEndDelayMS_ The auction end delay in milliseconds
    /// @return asyncId The ID of the batch
    function deliverPayload(
        PayloadDetails[] memory payloadDetails_,
        FeesData memory feesData_,
        uint256 auctionEndDelayMS_
    ) internal returns (bytes32) {
        address forwarderAppGateway = msg.sender;

        bytes32 asyncId = getCurrentAsyncId();
        asyncCounter++;

        for (uint256 i = 0; i < payloadDetails_.length; i++) {
            if (payloadDetails_[i].payload.length > 24.5 * 1024)
                revert PayloadTooLarge();
            // todo: convert it to proxy and promise call
            if (payloadDetails_[i].callType == CallType.DEPLOY) {
                payloadDetails_[i].payload = abi.encode(
                    DEPLOY,
                    payloadDetails_[i].payload
                );
                payloadDetails_[i].target = getPayloadDeliveryPlugAddress(
                    payloadDetails_[i].chainSlug
                );
            } else if (payloadDetails_[i].callType == CallType.WRITE) {
                forwarderAppGateway = IAddressResolver(addressResolver)
                    .contractsToGateways(msg.sender);

                if (forwarderAppGateway == address(0))
                    forwarderAppGateway = msg.sender;

                payloadDetails_[i].payload = abi.encode(
                    FORWARD_CALL,
                    abi.encode(
                        payloadDetails_[i].target,
                        payloadDetails_[i].payload
                    )
                );
                payloadDetails_[i].target = getPayloadDeliveryPlugAddress(
                    payloadDetails_[i].chainSlug
                );
            }

            if (payloadDetails_[i].callType != CallType.WITHDRAW) {
                // for callback to execute next payload and set addresses
                payloadDetails_[i].next[1] = IAddressResolver(addressResolver)
                    .deployAsyncPromiseContract(address(this));

                isValidPromise[payloadDetails_[i].next[1]] = true;
                IPromise(payloadDetails_[i].next[1]).then(
                    this.callback.selector,
                    abi.encode(asyncId)
                );
            }

            payloadDetailsArrays[asyncId].push(payloadDetails_[i]);
        }

        totalPayloadsRemaining[asyncId] = payloadDetails_.length;
        payloadBatches[asyncId] = PayloadBatch({
            appGateway: forwarderAppGateway,
            feesData: feesData_,
            currentPayloadIndex: 0,
            auctionEndDelayMS: auctionEndDelayMS_,
            isBatchCancelled: false
        });

        // deploy promise for callback from watcher precompile
        emit PayloadSubmitted(
            asyncId,
            forwarderAppGateway,
            payloadDetails_,
            feesData_,
            auctionEndDelayMS_
        );
        return asyncId;
    }

    /// @notice Cancels a transaction
    /// @param asyncId_ The ID of the batch
    function cancelTransaction(bytes32 asyncId_) external {
        if (msg.sender != payloadBatches[asyncId_].appGateway)
            revert("Only app gateway can cancel batch");

        payloadBatches[asyncId_].isBatchCancelled = true;
        emit BatchCancelled(asyncId_);
    }

    /// @notice Gets the payload delivery plug address
    /// @param chainSlug_ The chain identifier
    /// @return address The address of the payload delivery plug
    function getPayloadDeliveryPlugAddress(
        uint32 chainSlug_
    ) public view returns (address) {
        return watcherPrecompile().appGatewayPlugs(address(this), chainSlug_);
    }

    /// @notice Gets the current async ID
    /// @return bytes32 The current async ID
    function getCurrentAsyncId() public view returns (bytes32) {
        return bytes32((uint256(uint160(address(this))) << 64) | asyncCounter);
    }

    /// @notice Gets the payload details for a given index
    /// @param asyncId_ The ID of the batch
    /// @param index_ The index of the payload
    /// @return PayloadDetails The payload details
    function getPayloadDetails(
        bytes32 asyncId_,
        uint256 index_
    ) external view returns (PayloadDetails memory) {
        return payloadDetailsArrays[asyncId_][index_];
    }
}
