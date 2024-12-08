// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../SuperToken.sol";
import "../LimitHook.sol";
import "../../../base/AppDeployerBase.sol";
import "../../../utils/Ownable.sol";

contract SuperTokenDeployer is AppDeployerBase, Ownable {
    bytes32 public superToken = _createContractId("superToken");
    bytes32 public limitHook = _createContractId("limitHook");

    constructor(
        address addressResolver_,
        address owner_,
        uint256 _burnLimit,
        uint256 _mintLimit,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address initialSupplyHolder_,
        uint256 initialSupply_,
        FeesData memory feesData_
    ) AppDeployerBase(addressResolver_) Ownable(owner_) {
        creationCodeWithArgs[superToken] = abi.encodePacked(
            type(SuperToken).creationCode,
            abi.encode(
                name_,
                symbol_,
                decimals_,
                initialSupplyHolder_,
                initialSupply_
            )
        );

        creationCodeWithArgs[limitHook] = abi.encodePacked(
            type(LimitHook).creationCode,
            abi.encode(_burnLimit, _mintLimit)
        );

        _setFeesData(feesData_);
    }

    function deployContracts(uint32 chainSlug) external async {
        _deploy(superToken, chainSlug);
        _deploy(limitHook, chainSlug);
    }

    // don't need to call this directly, will be called automatically after all contracts are deployed.
    // check AppDeployerBase.allPayloadsExecuted and AppGateway.queueAndDeploy
    function initialize(uint32 chainSlug) public override async {
        address limitHookContract = getOnChainAddress(limitHook, chainSlug);
        SuperToken(forwarderAddresses[superToken][chainSlug]).setLimitHook(
            limitHookContract
        );
    }
}
