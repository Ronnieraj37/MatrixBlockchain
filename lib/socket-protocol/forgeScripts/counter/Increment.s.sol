// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Console.sol";
import {CounterComposer} from "../../contracts/apps/counter/app-gateway/CounterComposer.sol";
import {CounterDeployer} from "../../contracts/apps/counter/app-gateway/CounterDeployer.sol";
import {Counter} from "../../contracts/apps/counter/Counter.sol";
import {FeesData} from "../../contracts/common/Structs.sol";
import {ETH_ADDRESS} from "../../contracts/common/Constants.sol";

contract Increment is Script {
    function run() external {
        vm.startBroadcast();
        CounterComposer composer = CounterComposer(
            0x23EF7Af3bC1009EA6f95c3389921d5cB19950182
        );
        address forwarder = 0x9F2B173855cEB4625De1052428F085FdEe9A54D8;
        composer.incrementCounter(forwarder, 100);
    }
}
