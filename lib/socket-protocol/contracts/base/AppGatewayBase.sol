// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../utils/AddressResolverUtil.sol";
import "../interfaces/IAuctionHouse.sol";
import "../interfaces/IAppGateway.sol";
import "../interfaces/IPromise.sol";
import {FeesData} from "../common/Structs.sol";
import {FeesPlugin} from "../utils/FeesPlugin.sol";

/// @title AppGatewayBase
/// @notice Abstract contract for the app gateway
abstract contract AppGatewayBase is
    AddressResolverUtil,
    IAppGateway,
    FeesPlugin
{
    bool public override isReadCall;
    uint256 auctionDelayInMs;
    mapping(address => bool) public isValidPromise;

    error InvalidPromise();
    error FeesDataNotSet();

    /// @notice Modifier to treat functions async
    modifier async() {
        if (feesData.feePoolChain == 0) revert FeesDataNotSet();
        auctionHouse().clearQueue();
        addressResolver.clearPromises();
        _;
        auctionHouse().batch(feesData, auctionDelayInMs);
        _markValidPromises();
    }

    /// @notice Modifier to ensure only valid promises can call the function
    /// @dev only valid promises can call the function
    modifier onlyPromises() {
        if (!isValidPromise[msg.sender]) revert InvalidPromise();
        // remove promise once resolved
        isValidPromise[msg.sender] = false;
        _;
    }

    /// @notice Constructor for AppGatewayBase
    /// @param _addressResolver The address resolver address
    constructor(
        address _addressResolver
    ) AddressResolverUtil(_addressResolver) {}

    /// @notice Creates a contract ID
    /// @param contractName_ The contract name
    /// @return bytes32 The contract ID
    function _createContractId(
        string memory contractName_
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(contractName_));
    }

    /// @notice Sets the auction delay in milliseconds
    /// @param auctionDelayInMs_ The auction delay in milliseconds
    function _setAuctionDelayInMs(uint256 auctionDelayInMs_) internal {
        auctionDelayInMs = auctionDelayInMs_;
    }

    /// @notice Sets the read call flag
    function _readCallOn() internal {
        isReadCall = true;
    }

    /// @notice Turns off the read call flag
    function _readCallOff() internal {
        isReadCall = false;
    }

    /// @notice Marks the promises as valid
    function _markValidPromises() internal {
        address[] memory promises = addressResolver.getPromises();
        for (uint256 i = 0; i < promises.length; i++) {
            isValidPromise[promises[i]] = true;
        }
    }

    /// @notice Gets the current async ID
    /// @return bytes32 The current async ID
    function _getCurrentAsyncId() internal view returns (bytes32) {
        return auctionHouse().getCurrentAsyncId();
    }

    /// @notice Reverts the transaction
    /// @param asyncId_ The async ID
    function _revertTx(bytes32 asyncId_) internal {
        auctionHouse().cancelTransaction(asyncId_);
    }

    /// @notice Withdraws fee tokens
    /// @param chainSlug_ The chain slug
    /// @param token_ The token address
    /// @param amount_ The amount
    /// @param receiver_ The receiver address
    function _withdrawFeeTokens(
        uint32 chainSlug_,
        address token_,
        uint256 amount_,
        address receiver_
    ) internal {
        auctionHouse().withdrawTo(
            chainSlug_,
            token_,
            amount_,
            receiver_,
            feesData
        );
    }

    /// @notice Callback in pd promise to be called after all contracts are deployed
    /// @param chainSlug_ The chain slug
    function allContractsDeployed(
        uint32 chainSlug_
    ) external virtual onlyPayloadDelivery {}
}
