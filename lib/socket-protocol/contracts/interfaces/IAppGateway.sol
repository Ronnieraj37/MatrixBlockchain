// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IAppGateway {
    function isReadCall() external view returns (bool);

    function allContractsDeployed(uint32 chainSlug) external;
}
