// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "../../utils/Ownable.sol";

contract LimitHook is Ownable {
    // Define any state variables or functions for the LimitHook contract here
    uint256 public burnLimit;
    uint256 public mintLimit;

    error BurnLimitExceeded();
    error MintLimitExceeded();

    constructor(uint256 _burnLimit, uint256 _mintLimit) Ownable(msg.sender) {
        burnLimit = _burnLimit;
        mintLimit = _mintLimit;
    }

    function setLimits(
        uint256 _burnLimit,
        uint256 _mintLimit
    ) external onlyOwner {
        burnLimit = _burnLimit;
        mintLimit = _mintLimit;
    }

    function beforeBurn(uint256 amount_) external view {
        if (amount_ > burnLimit) revert BurnLimitExceeded();
    }

    function beforeMint(uint256 amount_) external view {
        if (amount_ > mintLimit) revert MintLimitExceeded();
    }
}
