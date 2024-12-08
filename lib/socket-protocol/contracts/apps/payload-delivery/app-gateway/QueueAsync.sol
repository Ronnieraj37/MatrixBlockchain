// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {AddressResolverUtil} from "../../../utils/AddressResolverUtil.sol";
import {IAuctionHouse} from "../../../interfaces/IAuctionHouse.sol";
import {IAppGateway} from "../../../interfaces/IAppGateway.sol";
import {IAddressResolver} from "../../../interfaces/IAddressResolver.sol";
import {CallParams, FeesData, PayloadDetails, CallType} from "../../../common/Structs.sol";
import {AsyncPromise} from "../../../AsyncPromise.sol";
import {IPromise} from "../../../interfaces/IPromise.sol";
import {IAppDeployer} from "../../../interfaces/IAppDeployer.sol";

/// @title QueueAsync
/// @notice Abstract contract for managing asynchronous payloads
abstract contract QueueAsync is IAuctionHouse, AddressResolverUtil {
    CallParams[] public callParamsArray;
    uint256 public saltCounter;
    mapping(address => bool) public isValidPromise;

    error InvalidPromise();

    modifier onlyPromises() {
        if (!isValidPromise[msg.sender]) revert InvalidPromise();
        // remove promise once resolved
        isValidPromise[msg.sender] = false;
        _;
    }

    constructor(
        address _addressResolver
    ) AddressResolverUtil(_addressResolver) {}

    /// @notice Clears the call parameters array
    function clearQueue() public {
        delete callParamsArray;
    }

    /// @notice Queues a new payload
    /// @param chainSlug_ The chain identifier
    /// @param target_ The target address
    /// @param asyncPromiseOrId_ The async promise or ID
    /// @param callType_ The call type
    /// @param payload_ The payload
    function queue(
        uint32 chainSlug_,
        address target_,
        bytes32 asyncPromiseOrId_,
        CallType callType_,
        bytes memory payload_
    ) external {
        callParamsArray.push(
            CallParams({
                callType: callType_,
                asyncPromiseOrId: asyncPromiseOrId_,
                chainSlug: chainSlug_,
                target: target_,
                payload: payload_,
                gasLimit: 10000000
            })
        );
    }

    /// @notice Creates an array of payload details
    /// @return payloadDetailsArray An array of payload details
    function createPayloadDetailsArray()
        internal
        returns (PayloadDetails[] memory payloadDetailsArray)
    {
        payloadDetailsArray = new PayloadDetails[](callParamsArray.length);

        for (uint256 i = 0; i < callParamsArray.length; i++) {
            CallParams memory params = callParamsArray[i];
            PayloadDetails memory payloadDetails = getPayloadDetails(params);
            payloadDetailsArray[i] = payloadDetails;
        }

        clearQueue();
    }

    /// @notice Gets the payload details for a given call parameters
    /// @param params The call parameters
    /// @return payloadDetails The payload details
    function getPayloadDetails(
        CallParams memory params
    ) internal returns (PayloadDetails memory) {
        address[] memory next = new address[](2);
        next[0] = address(uint160(uint256(params.asyncPromiseOrId)));

        bytes memory payload = params.payload;
        if (params.callType == CallType.DEPLOY) {
            address asyncPromise = IAddressResolver(addressResolver)
                .deployAsyncPromiseContract(address(this));

            isValidPromise[asyncPromise] = true;
            next[0] = asyncPromise;

            IPromise(asyncPromise).then(
                this.setAddress.selector,
                abi.encode(
                    params.chainSlug,
                    params.asyncPromiseOrId,
                    msg.sender
                )
            );

            bytes32 salt = keccak256(
                abi.encode(msg.sender, params.chainSlug, saltCounter++)
            );
            payload = abi.encode(params.payload, salt);
        }

        return
            PayloadDetails({
                chainSlug: params.chainSlug,
                target: params.target,
                payload: payload,
                callType: params.callType,
                executionGasLimit: params.gasLimit == 0
                    ? 1_000_000
                    : params.gasLimit,
                next: next
            });
    }

    /// @notice Sets the address for a deployed contract
    /// @param data_ The data
    /// @param returnData_ The return data
    function setAddress(
        bytes memory data_,
        bytes memory returnData_
    ) external onlyPromises {
        (uint32 chainSlug, bytes32 contractId, address appDeployer) = abi
            .decode(data_, (uint32, bytes32, address));

        address forwarderContractAddress = addressResolver
            .deployForwarderContract(
                appDeployer,
                abi.decode(returnData_, (address)),
                chainSlug
            );

        IAppDeployer(appDeployer).setForwarderContract(
            chainSlug,
            forwarderContractAddress,
            contractId
        );
    }
}
