// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CounterComposer} from "../contracts/apps/counter/app-gateway/CounterComposer.sol";
import {CounterDeployer} from "../contracts/apps/counter/app-gateway/CounterDeployer.sol";
import {Counter} from "../contracts/apps/counter/Counter.sol";
import "./AuctionHouse.sol";

contract CounterTest is AuctionHouseTest {
    function testCounter() external {
        console.log("Deploying contracts on Arbitrum...");
        setUpAuctionHouse();
        CounterDeployer deployer = new CounterDeployer(
            address(addressResolver),
            createFeesData(0.01 ether)
        );

        CounterComposer composer = new CounterComposer(
            address(addressResolver),
            address(deployer),
            createFeesData(0.01 ether)
        );

        console.log("Contracts deployed:");
        console.log("Deployer:", address(deployer));
        console.log("Composer:", address(composer));

        console.log("Deploying contracts on Arbitrum...");
        deployer.deployContracts(421614);

        console.log("Deploying contracts on Optimism...");
        deployer.deployContracts(11155420);
    }
}
