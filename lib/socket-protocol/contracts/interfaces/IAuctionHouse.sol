// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
import {PayloadDetails, Bid, FeesData, DeployParams, CallType} from "../common/Structs.sol";

interface IAuctionHouse {
    event BidPlaced(
        bytes32 indexed asyncId,
        Bid bid // Replaced transmitter and bidAmount with Bid struct
    );

    event AuctionEnded(
        bytes32 indexed asyncId,
        Bid winningBid // Replaced winningTransmitter and winningBid with Bid struct
    );

    function clearQueue() external;

    function bid(
        bytes32 asyncId_,
        uint256 fee,
        bytes memory transmitterSignature
    ) external;

    function queue(
        uint32 chainSlug_,
        address target_,
        bytes32 asyncPromiseOrId_,
        CallType callType_,
        bytes memory payload_
    ) external;

    function batch(
        FeesData memory feesData_,
        uint256 auctionEndDelayMS_
    ) external returns (bytes32);

    function withdrawTo(
        uint32 chainSlug_,
        address token_,
        uint256 amount_,
        address receiver_,
        FeesData memory feesData_
    ) external;

    function cancelTransaction(bytes32 asyncId_) external;

    function getCurrentAsyncId() external view returns (bytes32);
}
