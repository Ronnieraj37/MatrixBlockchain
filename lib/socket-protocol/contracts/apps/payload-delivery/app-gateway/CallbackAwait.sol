// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAppGateway} from "../../../interfaces/IAppGateway.sol";
import {Ownable} from "../../../utils/Ownable.sol";
import {Bid, PayloadBatch, FeesData, PayloadDetails, FinalizeParams} from "../../../common/Structs.sol";
import {DISTRIBUTE_FEE, DEPLOY} from "../../../common/Constants.sol";
import "./BatchAsync.sol";

// msg.sender map and call next function flow
abstract contract CallbackAwait is BatchAsync, Ownable(msg.sender) {
    mapping(bytes32 => Bid) public winningBids;
    // asyncId => auction status
    mapping(bytes32 => bool) public auctionClosed;
    uint256 public feesCounter;

    // payloadId => asyncId
    mapping(bytes32 => bytes32) public payloadIdToBatchHash;
    mapping(uint32 => uint256) public feeCollectionGasLimit;

    /// @notice Constructor for CallbackAwait
    /// @param addressResolver_ The address of the address resolver
    constructor(address addressResolver_) QueueAsync(addressResolver_) {
        // todo: fix later
        feeCollectionGasLimit[421614] = 2000000;
        feeCollectionGasLimit[11155420] = 1000000;
        feeCollectionGasLimit[11155111] = 1000000;
        feeCollectionGasLimit[84532] = 1000000;
    }

    /// @notice Sets the fee collection gas limits
    /// @param chainSlugs An array of chain slugs
    /// @param gasLimits An array of gas limits
    function setFeeCollectionGasLimits(
        uint32[] memory chainSlugs,
        uint256[] memory gasLimits
    ) external {
        require(
            chainSlugs.length == gasLimits.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < chainSlugs.length; i++) {
            feeCollectionGasLimit[chainSlugs[i]] = gasLimits[i];
        }
    }

    /// @notice Starts the batch processing
    /// @param asyncId_ The ID of the batch
    function _startBatchProcessing(bytes32 asyncId_) internal {
        PayloadBatch storage payloadBatch = payloadBatches[asyncId_];
        if (payloadBatch.isBatchCancelled) return;

        _finalizeNextPayload(asyncId_);
    }

    /// @notice Callback function for handling promises
    /// @param asyncId_ The ID of the batch
    /// @param payloadDetails_ The payload details
    function callback(
        bytes memory asyncId_,
        bytes memory payloadDetails_
    ) external override onlyPromises {
        bytes32 asyncId = abi.decode(asyncId_, (bytes32));
        PayloadBatch storage payloadBatch = payloadBatches[asyncId];
        if (payloadBatch.isBatchCancelled) return;

        uint256 payloadsRemaining = totalPayloadsRemaining[asyncId];

        if (payloadsRemaining > 0) {
            payloadBatch.currentPayloadIndex++;
            _finalizeNextPayload(asyncId);
        } else {
            _createFeesSignature(
                asyncId,
                payloadBatch.appGateway,
                payloadBatch.feesData,
                winningBids[asyncId]
            );

            PayloadDetails storage payloadDetails = payloadDetailsArrays[
                asyncId
            ][payloadBatch.currentPayloadIndex];
            if (payloadDetails.callType == CallType.DEPLOY) {
                IAppGateway(payloadBatch.appGateway).allContractsDeployed(
                    payloadDetails.chainSlug
                );
            }
        }
    }

    /// @notice Finalizes the next payload in the batch
    /// @param asyncId_ The ID of the batch
    function _finalizeNextPayload(bytes32 asyncId_) internal {
        PayloadBatch storage payloadBatch = payloadBatches[asyncId_];
        uint256 currentPayloadIndex = payloadBatch.currentPayloadIndex;
        totalPayloadsRemaining[asyncId_]--;

        PayloadDetails[] storage payloads = payloadDetailsArrays[asyncId_];

        PayloadDetails storage payloadDetails = payloads[currentPayloadIndex];

        bytes32 payloadId;
        bytes32 root;

        if (payloadDetails.callType == CallType.READ) {
            payloadId = watcherPrecompile().query(
                payloadDetails.chainSlug,
                payloadDetails.target,
                payloadDetails.next,
                payloadDetails.payload
            );
            payloadIdToBatchHash[payloadId] = asyncId_;
        } else {
            FinalizeParams memory finalizeParams = FinalizeParams({
                payloadDetails: payloadDetails,
                transmitter: winningBids[asyncId_].transmitter
            });

            (payloadId, root) = watcherPrecompile().finalize(finalizeParams);
            payloadIdToBatchHash[payloadId] = asyncId_;
        }

        emit PayloadAsyncRequested(asyncId_, payloadId, root, payloadDetails);
    }

    /// @notice Creates a fees signature
    /// @param asyncId_ The ID of the batch
    /// @param appGateway_ The address of the app gateway
    /// @param feesData_ The fees data
    /// @param winningBid_ The winning bid
    function _createFeesSignature(
        bytes32 asyncId_,
        address appGateway_,
        FeesData memory feesData_,
        Bid memory winningBid_
    ) internal {
        // Create payload for pool contract
        bytes memory payload = abi.encode(
            DISTRIBUTE_FEE,
            abi.encode(
                appGateway_,
                feesData_.feePoolToken,
                winningBid_.fee,
                winningBid_.transmitter,
                feesCounter++
            )
        );

        PayloadDetails memory payloadDetails = PayloadDetails({
            chainSlug: feesData_.feePoolChain,
            target: getPayloadDeliveryPlugAddress(feesData_.feePoolChain),
            payload: payload,
            callType: CallType.WRITE,
            executionGasLimit: feeCollectionGasLimit[feesData_.feePoolChain],
            next: new address[](0)
        });

        FinalizeParams memory finalizeParams = FinalizeParams({
            payloadDetails: payloadDetails,
            transmitter: winningBid_.transmitter
        });

        (bytes32 payloadId, bytes32 root) = watcherPrecompile().finalize(
            finalizeParams
        );
        payloadIdToBatchHash[payloadId] = asyncId_;
        emit PayloadAsyncRequested(asyncId_, payloadId, root, payloadDetails);
    }
}
