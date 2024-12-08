// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {DEPLOY, CONFIGURE, ETH_ADDRESS} from "../../common/Constants.sol";

/// @title ContractFactory
/// @notice Abstract contract for deploying contracts
abstract contract ContractFactory {
    event Deployed(address addr, bytes32 salt);

    /// @notice Handles the deployment of a contract
    /// @param data The data
    /// @return bytes memory The encoded deployed address
    function _handleDeploy(bytes memory data) internal returns (bytes memory) {
        address deployedAddress = deployContract(data);
        return abi.encode(deployedAddress);
    }

    /// @notice Deploys a contract
    /// @param data The data
    /// @return address The deployed address
    function deployContract(
        bytes memory data
    ) public payable returns (address) {
        (bytes memory creationCode, bytes32 salt) = abi.decode(
            data,
            (bytes, bytes32)
        );

        address addr;
        assembly {
            addr := create2(
                callvalue(),
                add(creationCode, 0x20),
                mload(creationCode),
                salt
            )
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, salt);
        return addr;
    }

    /// @notice Gets the address for a deployed contract
    /// @param creationCode The creation code
    /// @param salt The salt
    /// @return address The deployed address
    function getAddress(
        bytes memory creationCode,
        uint256 salt
    ) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(creationCode)
            )
        );

        return address(uint160(uint256(hash)));
    }
}
