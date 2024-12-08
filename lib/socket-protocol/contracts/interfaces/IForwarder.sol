// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IForwarder {
    // View functions
    function getOnChainAddress() external view returns (address);

    function getChainSlug() external view returns (uint32);
}
