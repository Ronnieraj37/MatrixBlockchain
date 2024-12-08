// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "../../interfaces/ISwitchboard.sol";
import "../../interfaces/ISignatureVerifier.sol";
import "../../interfaces/ISocket.sol";
import "../utils/AccessControl.sol";

abstract contract SwitchboardBase is ISwitchboard, AccessControl {
    // signature verifier contract
    ISignatureVerifier public immutable signatureVerifier__;

    ISocket public immutable socket__;

    // chain slug of deployed chain
    uint32 public immutable chainSlug;

    // incrementing nonce for each signer
    // watcher => nextNonce
    mapping(address => uint256) public nextNonce;

    // destinationChainSlug => initialPacketCount - packets with packetCount after this will be accepted at the switchboard.
    // This is to prevent attacks with sending payloads for chain slugs before the switchboard is registered for them.
    mapping(uint32 => uint256) public initialPacketCount;

    // Error hit when a signature with unexpected nonce is received
    error InvalidNonce();

    bytes32 constant WATCHER_ROLE = keccak256("WATCHER_ROLE");

    /**
     * @dev Constructor of SwitchboardBase
     * @param chainSlug_ Chain slug of deployment chain
     * @param signatureVerifier_ signatureVerifier_ contract
     */
    constructor(
        uint32 chainSlug_,
        ISocket socket_,
        ISignatureVerifier signatureVerifier_,
        address owner_
    ) AccessControl(owner_) {
        chainSlug = chainSlug_;
        socket__ = socket_;
        signatureVerifier__ = signatureVerifier_;
    }
}
