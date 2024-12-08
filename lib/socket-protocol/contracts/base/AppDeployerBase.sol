// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {DeployParams, FeesData, CallType} from "../common/Structs.sol";
import {AppGatewayBase} from "./AppGatewayBase.sol";
import {IForwarder} from "../interfaces/IForwarder.sol";
import {IAppDeployer} from "../interfaces/IAppDeployer.sol";
import {IAuctionHouse} from "../interfaces/IAuctionHouse.sol";

/// @title AppDeployerBase
/// @notice Abstract contract for deploying applications
abstract contract AppDeployerBase is AppGatewayBase, IAppDeployer {
    mapping(bytes32 => mapping(uint32 => address)) public forwarderAddresses;
    mapping(bytes32 => bytes) public creationCodeWithArgs;

    constructor(address _addressResolver) AppGatewayBase(_addressResolver) {}

    /// @notice Deploys a contract
    /// @param contractId_ The contract ID
    /// @param chainSlug_ The chain slug
    function _deploy(bytes32 contractId_, uint32 chainSlug_) internal {
        IAuctionHouse(auctionHouse()).queue(
            chainSlug_,
            address(0),
            // hacked for contract addr, need to revisit
            contractId_,
            CallType.DEPLOY,
            creationCodeWithArgs[contractId_]
        );
    }

    /// @notice Sets the forwarder contract
    /// @param chainSlug The chain slug
    /// @param forwarderContractAddr The forwarder contract address
    /// @param contractId The contract ID
    /// @dev callback in payload delivery promise after contract deployment
    function setForwarderContract(
        uint32 chainSlug,
        address forwarderContractAddr,
        bytes32 contractId
    ) external onlyPayloadDelivery {
        forwarderAddresses[contractId][chainSlug] = forwarderContractAddr;
    }

    /// @notice Gets the on-chain address
    /// @param contractId The contract ID
    /// @param chainSlug The chain slug
    /// @return onChainAddress The on-chain address
    function getOnChainAddress(
        bytes32 contractId,
        uint32 chainSlug
    ) public view returns (address onChainAddress) {
        if (forwarderAddresses[contractId][chainSlug] == address(0)) {
            return address(0);
        }

        onChainAddress = IForwarder(forwarderAddresses[contractId][chainSlug])
            .getOnChainAddress();
    }

    /// @notice Callback in pd promise to be called after all contracts are deployed
    /// @param chainSlug The chain slug
    /// @dev only payload delivery can call this
    /// @dev callback in pd promise to be called after all contracts are deployed
    function allContractsDeployed(
        uint32 chainSlug
    ) external override onlyPayloadDelivery {
        initialize(chainSlug);
    }

    /// @notice Gets the socket address
    /// @param chainSlug The chain slug
    /// @return socketAddress The socket address
    function getSocketAddress(uint32 chainSlug) public view returns (address) {
        return
            watcherPrecompile().appGatewayPlugs(
                addressResolver.auctionHouse(),
                chainSlug
            );
    }

    /// @notice Initializes the contract
    /// @param chainSlug The chain slug
    function initialize(uint32 chainSlug) public virtual {}
}
