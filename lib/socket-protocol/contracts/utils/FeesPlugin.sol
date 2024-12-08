// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FeesData} from "../common/Structs.sol";

/// @title FeesPlugin
/// @notice Abstract contract for managing fee configurations
/// @dev Provides base functionality for fee management in the system
abstract contract FeesPlugin {
    /// @notice Storage for the current fee configuration
    /// @dev Contains fee parameters like rates, limits, and recipient addresses
    FeesData public feesData;

    /// @notice Updates the fee configuration
    /// @param feesData_ New fee configuration to be set
    /// @dev Internal function to be called by inheriting contracts
    /// @dev Should be protected with appropriate access control in implementing contracts
    function _setFeesData(FeesData memory feesData_) internal {
        // Update the fee configuration with new parameters
        feesData = feesData_;
    }

    /// @notice Retrieves the current fee configuration
    /// @return Current fee configuration struct
    /// @dev Public view function accessible to any caller
    /// @dev Used by external contracts to verify fee parameters
    function getFeesData() public view returns (FeesData memory) {
        return feesData;
    }
}
