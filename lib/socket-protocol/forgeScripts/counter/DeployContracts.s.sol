// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Console.sol";
import {CounterComposer} from "../../contracts/apps/counter/app-gateway/CounterComposer.sol";
import {CounterDeployer} from "../../contracts/apps/counter/app-gateway/CounterDeployer.sol";
import {Counter} from "../../contracts/apps/counter/Counter.sol";
import {FeesData} from "../../contracts/common/Structs.sol";
import {ETH_ADDRESS} from "../../contracts/common/Constants.sol";

contract DeployContracts is Script {
    function run() external {
        vm.startBroadcast();
        CounterDeployer deployer = CounterDeployer(
            0x12103e799d8887034d4560A960C2410ceE751004
        );
        deployer.deployContracts(421614);
    }
}
