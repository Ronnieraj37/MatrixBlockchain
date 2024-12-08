// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {SuperTokenApp} from "../../contracts/apps/super-token/app-gateway/SuperTokenApp.sol";

contract Bridge is Script {
    struct UserOrder {
        address srcToken;
        address dstToken;
        address user;
        uint256 srcAmount;
        uint256 deadline;
    }

    function run() external {
        vm.startBroadcast();

        UserOrder memory order = UserOrder({
            srcToken: 0x047Db07E30809f87CABA2E552585F9A727a074ED,
            dstToken: 0x4545C7bc6347945e7bfda082a2A0033cE4C7CEae,
            user: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            srcAmount: 1000,
            deadline: block.timestamp + 1 days
        });

        SuperTokenApp gateway = SuperTokenApp(
            0xb1F4CbFCE786aA8B553796Fb06c04Dd461967A16
        );
        gateway.bridge(abi.encode(order));
    }
}
