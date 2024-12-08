// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20.sol";
import {Ownable} from "../../utils/Ownable.sol";
import {LimitHook} from "./LimitHook.sol";

/**
 * @title SuperToken
 * @notice An ERC20 contract which enables bridging a token to its sibling chains.
 */
contract SuperToken is ERC20, Ownable(msg.sender) {
    address public controller;
    LimitHook public limitHook;
    mapping(address => uint256) public lockedTokens;

    error InsufficientBalance();
    error InsufficientLockedTokens();
    error NotController();

    modifier onlyController() {
        if (msg.sender != controller) revert NotController();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address initialSupplyHolder_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_, decimals_) {
        _mint(initialSupplyHolder_, initialSupply_);
        controller = msg.sender;
    }

    function lockTokens(
        address user_,
        uint256 amount_
    ) external onlyController {
        if (balanceOf[user_] < amount_) revert InsufficientBalance();
        limitHook.beforeBurn(amount_);

        lockedTokens[user_] += amount_;
        _burn(user_, amount_);
    }

    function mint(address receiver_, uint256 amount_) external onlyController {
        limitHook.beforeMint(amount_);
        _mint(receiver_, amount_);
    }

    function burn(address user_, uint256 amount_) external onlyController {
        lockedTokens[user_] -= amount_;
    }

    function unlockTokens(
        address user_,
        uint256 amount_
    ) external onlyController {
        if (lockedTokens[user_] < amount_) revert InsufficientLockedTokens();
        lockedTokens[user_] -= amount_;
        _mint(user_, amount_);
    }

    function setController(address newController_) external onlyOwner {
        controller = newController_;
    }

    function setLimitHook(address limitHook_) external onlyOwner {
        limitHook = LimitHook(limitHook_);
    }
}
