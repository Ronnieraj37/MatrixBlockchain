// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

// contains role hashes used in socket for various different operations

// used to rescue funds
bytes32 constant RESCUE_ROLE = keccak256("RESCUE_ROLE");
// used by governance
bytes32 constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
// used by transmitters who seal and propose packets in socket
bytes32 constant TRANSMITTER_ROLE = keccak256("TRANSMITTER_ROLE");
// used by switchboard watchers who work against transmitters
bytes32 constant WATCHER_ROLE = keccak256("WATCHER_ROLE");
