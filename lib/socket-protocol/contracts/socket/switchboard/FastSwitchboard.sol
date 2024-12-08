// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "./SwitchboardBase.sol";

/**
 * @title FastSwitchboard contract
 * @dev This contract implements a fast version of the SwitchboardBase contract
 * that enables packet attestations and watchers registration.
 */
contract FastSwitchboard is SwitchboardBase {
    // used to track which watcher have attested a root
    // watcher => root => isAttested
    mapping(bytes32 => bool) public isAttested;

    // Error emitted when a root is already attested by a specific watcher.
    // This is hit even if they are attesting a new proposalCount with same root.
    error AlreadyAttested();
    error WatcherNotFound();
    event Attested(bytes32 payloadId, bytes32 root_, address watcher);

    /**
     * @dev Constructor function for the FastSwitchboard contract
     * @param chainSlug_ Chain slug of the chain where the contract is deployed
     * @param signatureVerifier_ The address of the signature verifier contract
     */
    constructor(
        uint32 chainSlug_,
        ISocket socket_,
        ISignatureVerifier signatureVerifier_,
        address owner_
    ) SwitchboardBase(chainSlug_, socket_, signatureVerifier_, owner_) {}

    /**
     * @dev Function to attest a packet
     * @param payloadId_ Packet ID
     * @param root_ Root of the packet
     * @param signature_ Signature of the watcher
     * @notice we are attesting a root uniquely identified with packetId and proposalCount. However,
     * there can be multiple proposals for same root. To avoid need to re-attest for different proposals
     *  with same root, we are storing attestations against root instead of packetId and proposalCount.
     */
    function attest(
        bytes32 payloadId_,
        bytes32 root_,
        bytes calldata signature_
    ) external {
        // removed root verification for now

        // todo: can include orderHash, transmitter, bidAmount in digest and verify these
        // here instead of including in root
        address watcher = signatureVerifier__.recoverSigner(
            keccak256(abi.encode(address(this), root_)),
            signature_
        );

        if (isAttested[root_]) revert AlreadyAttested();
        if (!_hasRole(WATCHER_ROLE, watcher)) revert WatcherNotFound();

        isAttested[root_] = true;
        emit Attested(payloadId_, root_, watcher);
    }

    /**
     * @inheritdoc ISwitchboard
     */
    function allowPacket(bytes32 root_, bytes32) external view returns (bool) {
        // root has enough attestations
        if (isAttested[root_]) return true;

        // not enough attestations and timeout not hit
        return false;
    }

    /**
     * @notice adds a watcher for `srcChainSlug_` chain
     * @param watcher_ watcher address
     */
    function grantWatcherRole(address watcher_) external onlyOwner {
        _grantRole(WATCHER_ROLE, watcher_);
    }

    /**
     * @notice removes a watcher from `srcChainSlug_` chain list
     * @param watcher_ watcher address
     */
    function revokeWatcherRole(address watcher_) external onlyOwner {
        _revokeRole(WATCHER_ROLE, watcher_);
    }

    function registerSwitchboard() external onlyOwner {
        socket__.registerSwitchboard();
    }
}
