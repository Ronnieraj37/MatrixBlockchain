// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MatrixDeployer} from "../src/MatrixDeployer.sol";
import {GlobalMatrixGateway} from "../src/GlobalMatrixGateway.sol";

contract MatrixChangePlayer is Script {
    function run() external {
        string memory socketRPC = vm.envString("SOCKET_RPC");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.createSelectFork(socketRPC);

        MatrixDeployer deployer = MatrixDeployer(
            vm.envAddress("COUNTER_DEPLOYER")
        );
        GlobalMatrixGateway gateway = GlobalMatrixGateway(
            vm.envAddress("COUNTER_APP_GATEWAY")
        );

        vm.startBroadcast(deployerPrivateKey);

        gateway.updatePlayerLocation(vm.envAddress("ACCOUNT1"), 5, 9);
        gateway.updatePlayerLocation(vm.envAddress("ACCOUNT2"), 1, 2);
    }
}
