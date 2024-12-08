// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant ETH_ADDRESS = address(
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
);

address constant ZERO_ADDRESS = address(0);

bytes32 constant FORWARD_CALL = keccak256("FORWARD_CALL");
bytes32 constant DISTRIBUTE_FEE = keccak256("DISTRIBUTE_FEE");
bytes32 constant DEPLOY = keccak256("DEPLOY");
bytes32 constant WITHDRAW = keccak256("WITHDRAW");
bytes32 constant CONFIGURE = keccak256("CONFIGURE");
bytes32 constant CONNECT = keccak256("CONNECT");

uint256 constant DEPLOY_GAS_LIMIT = 5_000_000;
uint256 constant CONFIGURE_GAS_LIMIT = 1_000_000;
