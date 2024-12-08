// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Console.sol";
import {CounterComposer} from "../../contracts/apps/counter/app-gateway/CounterComposer.sol";
import {CounterDeployer} from "../../contracts/apps/counter/app-gateway/CounterDeployer.sol";
import {Counter} from "../../contracts/apps/counter/Counter.sol";
import {FeesData} from "../../contracts/common/Structs.sol";
import {ETH_ADDRESS} from "../../contracts/common/Constants.sol";

contract DeployGateway is Script {
    function run() external {
        vm.startBroadcast();
        address addressResolver = 0x208dC31cd6042a09bbFDdB31614A337a51b870ba;
        FeesData memory feesData = FeesData({
            feePoolChain: 421614,
            feePoolToken: ETH_ADDRESS,
            maxFees: 0.001 ether
        });

        CounterDeployer deployer = new CounterDeployer(
            addressResolver,
            feesData
        );
        CounterComposer gateway = new CounterComposer(
            addressResolver,
            address(deployer),
            feesData
        );

        bytes32 counterPlug = deployer.counter();
        console.log("Contracts deployed:");
        console.log("CounterComposer:", address(gateway));
        console.log("Counter Deployer:", address(deployer));
        console.log("CounterIdentifier:");
        console.logBytes32(counterPlug);
    }
}
