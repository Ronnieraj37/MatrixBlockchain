// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import "../interfaces/IHasher.sol";
import "../interfaces/ISignatureVerifier.sol";

import "../libraries/RescueFundsLib.sol";
import "./SocketConfig.sol";

/**
 * @title SocketBase
 * @notice A contract that is responsible for common storage for src and dest contracts, governance
 * setters and inherits SocketConfig
 */
abstract contract SocketBase is SocketConfig {
    // Version string for this socket instance
    bytes32 public immutable version;
    // ChainSlug for this deployed socket instance
    uint32 public immutable chainSlug;

    /*
     * @notice constructor for creating a new Socket contract instance.
     * @param chainSlug_ The unique identifier of the chain this socket is deployed on.
     * @param hasher_ The address of the Hasher contract used to pack the payload before executing them.
     * @param owner_ The address of the owner who has the initial admin role.
     * @param version_ The version string which is hashed and stored in socket.
     */
    constructor(
        uint32 chainSlug_,
        address hasher_,
        address signatureVerifier_,
        address owner_,
        string memory version_
    ) AccessControl(owner_) {
        hasher__ = IHasher(hasher_);
        signatureVerifier__ = ISignatureVerifier(signatureVerifier_);
        chainSlug = chainSlug_;
        version = keccak256(bytes(version_));
    }

    ////////////////////////////////////////////////////////
    //////////// PERIPHERY CONTRACT CONNECTORS ////////////
    ////////////////////////////////////////////////////////

    // Hasher contract
    IHasher public hasher__;
    // Signature Verifier contract
    ISignatureVerifier public signatureVerifier__;

    ////////////////////////////////////////////////////////
    ////////////////////// ERRORS //////////////////////////
    ////////////////////////////////////////////////////////

    /**
     * @dev Error thrown when non-transmitter tries to execute
     */
    error InvalidTransmitter();

    ////////////////////////////////////////////////////////
    ////////////////////// EVENTS //////////////////////////
    ////////////////////////////////////////////////////////
    /**
     * @notice An event that is emitted when the hasher is updated.
     * @param hasher The address of the new hasher.
     */
    event HasherSet(address hasher);

    /**
     * @notice An event that is emitted when a new signatureVerifier contract is set
     * @param signatureVerifier address of new signatureVerifier contract
     */
    event SignatureVerifierSet(address signatureVerifier);

    //////////////////////////////////////////////////
    //////////// GOV Permissioned setters ////////////
    //////////////////////////////////////////////////

    /**
     * @notice updates hasher__
     * @dev Only governance can call this function
     * @param hasher_ address of hasher
     */
    function setHasher(address hasher_) external onlyRole(GOVERNANCE_ROLE) {
        hasher__ = IHasher(hasher_);
        emit HasherSet(hasher_);
    }

    /**
     * @notice updates hasher__
     * @dev Only governance can call this function
     * @param signatureVerifier_ address of signatureVerifier
     */
    function setSignatureVerifier(
        address signatureVerifier_
    ) external onlyRole(GOVERNANCE_ROLE) {
        signatureVerifier__ = ISignatureVerifier(signatureVerifier_);
        emit SignatureVerifierSet(signatureVerifier_);
    }

    //////////////////////////////////////////////
    //////////// Rescue role actions ////////////
    /////////////////////////////////////////////

    /**
     * @notice Rescues funds from the contract if they are locked by mistake. This contract does not
     * theoretically need this function but it is added for safety.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}
