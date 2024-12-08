// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MatrixDeployer} from "../src/MatrixDeployer.sol";
import {GlobalMatrixGateway} from "../src/GlobalMatrixGateway.sol";

contract MatrixAddMap is Script {
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

        address counterForwarderArbitrumSepolia = deployer.forwarderAddresses(
            deployer.counter(),
            421614
        );
        address counterForwarderOptimismSepolia = deployer.forwarderAddresses(
            deployer.counter(),
            11155420
        );
        address counterForwarderBaseSepolia = deployer.forwarderAddresses(
            deployer.counter(),
            84532
        );
        address counterForwarderSepolia = deployer.forwarderAddresses(
            deployer.counter(),
            11155111
        );

        // Count non-zero addresses
        uint256 nonZeroCount = 0;
        if (counterForwarderArbitrumSepolia != address(0)) nonZeroCount++;
        if (counterForwarderOptimismSepolia != address(0)) nonZeroCount++;
        if (counterForwarderBaseSepolia != address(0)) nonZeroCount++;
        if (counterForwarderSepolia != address(0)) nonZeroCount++;

        vm.startBroadcast(deployerPrivateKey);

        gateway.createMap();
        gateway.addPlayerInMap(vm.envAddress("ACCOUNT1"), 1);
        gateway.addPlayerInMap(vm.envAddress("ACCOUNT2"), 1);
    }
}
