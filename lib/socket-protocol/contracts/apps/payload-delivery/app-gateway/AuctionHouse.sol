// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAuctionHouse} from "../../../interfaces/IAuctionHouse.sol";
import {IAppGateway} from "../../../interfaces/IAppGateway.sol";
import {CallbackAwait} from "./CallbackAwait.sol";
import {Ownable} from "../../../utils/Ownable.sol";
import {SignatureVerifier} from "../../../socket/utils/SignatureVerifier.sol";
import {Bid, PayloadBatch, FeesData, PayloadDetails, FinalizeParams, CallType} from "../../../common/Structs.sol";
import {FORWARD_CALL, DISTRIBUTE_FEE, DEPLOY, WITHDRAW} from "../../../common/Constants.sol";

/// @title AuctionHouse
/// @notice Contract for managing auctions and placing bids
contract AuctionHouse is CallbackAwait {
    SignatureVerifier public immutable signatureVerifier__;

    /// @notice Constructor for AuctionHouse
    /// @param addressResolver_ The address of the address resolver
    /// @param signatureVerifier_ The address of the signature verifier
    constructor(
        address addressResolver_,
        SignatureVerifier signatureVerifier_
    ) CallbackAwait(addressResolver_) {
        signatureVerifier__ = signatureVerifier_;
    }

    /// @notice Places a bid for an auction
    /// @param asyncId_ The ID of the auction
    /// @param fee The bid amount
    /// @param transmitterSignature The signature of the transmitter
    function bid(
        bytes32 asyncId_,
        uint256 fee,
        bytes memory transmitterSignature
    ) external override {
        require(!auctionClosed[asyncId_], "Auction closed");

        address transmitter = signatureVerifier__.recoverSigner(
            keccak256(abi.encode(address(this), asyncId_, fee)),
            transmitterSignature
        );

        Bid memory newBid = Bid({fee: fee, transmitter: transmitter});
        PayloadBatch storage payloadBatch = payloadBatches[asyncId_];
        require(fee <= payloadBatch.feesData.maxFees, "Bid exceeds max fees");

        Bid memory oldBid = winningBids[asyncId_];

        if (oldBid.transmitter != address(0)) {
            require(newBid.fee < oldBid.fee, "Bid is not better");
        }

        winningBids[asyncId_] = newBid;
        emit BidPlaced(asyncId_, newBid);

        watcherPrecompile().setTimeout(
            abi.encodeWithSelector(this.endAuction.selector, asyncId_),
            payloadBatch.auctionEndDelayMS
        );
    }

    /// @notice Ends an auction
    /// @param asyncId_ The ID of the auction
    function endAuction(bytes32 asyncId_) external onlyWatcherPrecompile {
        auctionClosed[asyncId_] = true;
        Bid memory winningBid = winningBids[asyncId_];
        emit AuctionEnded(asyncId_, winningBid);

        _startBatchProcessing(asyncId_);
    }

    /// @notice Withdraws funds to a specified receiver
    /// @param chainSlug_ The chain identifier
    /// @param token_ The address of the token
    /// @param amount_ The amount of tokens to withdraw
    /// @param receiver_ The address of the receiver
    /// @param feesData_ The fees data
    function withdrawTo(
        uint32 chainSlug_,
        address token_,
        uint256 amount_,
        address receiver_,
        FeesData memory feesData_
    ) external {
        address appGateway_ = msg.sender;
        // Create payload for pool contract
        bytes memory payload = abi.encode(
            WITHDRAW,
            abi.encode(appGateway_, token_, amount_, receiver_)
        );
        PayloadDetails[] memory payloadDetailsArray = new PayloadDetails[](1);
        payloadDetailsArray[0] = PayloadDetails({
            chainSlug: chainSlug_,
            target: getPayloadDeliveryPlugAddress(chainSlug_),
            payload: payload,
            callType: CallType.WITHDRAW,
            executionGasLimit: feeCollectionGasLimit[chainSlug_],
            next: new address[](0)
        });

        deliverPayload(payloadDetailsArray, feesData_, 0);
    }
}
