// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Console.sol";
import {SuperTokenApp} from "../../contracts/apps/super-token/app-gateway/SuperTokenApp.sol";
import {SuperTokenDeployer} from "../../contracts/apps/super-token/app-gateway/SuperTokenDeployer.sol";
import {SuperToken} from "../../contracts/apps/super-token/SuperToken.sol";
import {FeesData} from "../../contracts/common/Structs.sol";
import {ETH_ADDRESS} from "../../contracts/common/Constants.sol";

contract DeployGateway is Script {
    function run() external {
        vm.startBroadcast();

        address addressResolver = 0x208dC31cd6042a09bbFDdB31614A337a51b870ba;
        address owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        FeesData memory feesData = FeesData({
            feePoolChain: 421614,
            feePoolToken: ETH_ADDRESS,
            maxFees: 0.001 ether
        });

        SuperTokenDeployer deployer = new SuperTokenDeployer(
            addressResolver,
            owner,
            10000000000000000000000,
            10000000000000000000000,
            "SUPER TOKEN",
            "SUPER",
            18,
            owner,
            1000000000 ether,
            feesData
        );

        SuperTokenApp gateway = new SuperTokenApp(
            addressResolver,
            address(deployer),
            feesData
        );

        bytes32 superToken = deployer.superToken();
        bytes32 limitHook = deployer.limitHook();

        console.log("Contracts deployed:");
        console.log("SuperTokenApp:", address(gateway));
        console.log("SuperTokenDeployer:", address(deployer));
        console.log("SuperTokenId:");
        console.logBytes32(superToken);
        console.log("LimitHookId:");
        console.logBytes32(limitHook);
    }
}
