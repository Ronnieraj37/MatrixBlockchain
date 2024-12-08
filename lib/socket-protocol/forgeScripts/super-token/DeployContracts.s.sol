// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Console.sol";
import {SuperTokenApp} from "../../contracts/apps/super-token/app-gateway/SuperTokenApp.sol";
import {SuperTokenDeployer} from "../../contracts/apps/super-token/app-gateway/SuperTokenDeployer.sol";
import {SuperToken} from "../../contracts/apps/super-token/SuperToken.sol";
import {FeesData} from "../../contracts/common/Structs.sol";
import {ETH_ADDRESS} from "../../contracts/common/Constants.sol";

contract DeployContracts is Script {
    function run() external {
        vm.startBroadcast();
        SuperTokenDeployer deployer = SuperTokenDeployer(
            0x02520426a04D2943d817A60ABa37ab25bA10e630
        );
        deployer.deployContracts(84532);
        deployer.deployContracts(11155111);
    }
}
