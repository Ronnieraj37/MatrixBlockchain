// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MatrixDeployer} from "../src/MatrixDeployer.sol";
import {GlobalMatrixGateway} from "../src/GlobalMatrixGateway.sol";

contract MatrixAddPlayers is Script {
    function run() external {
        string memory socketRPC = vm.envString("SOCKET_RPC");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.createSelectFork(socketRPC);

        MatrixDeployer deployer = MatrixDeployer(vm.envAddress("COUNTER_DEPLOYER"));
        GlobalMatrixGateway gateway = GlobalMatrixGateway(vm.envAddress("COUNTER_APP_GATEWAY"));

        address counterForwarderArbitrumSepolia = deployer.forwarderAddresses(deployer.counter(), 421614);
        address counterForwarderOptimismSepolia = deployer.forwarderAddresses(deployer.counter(), 11155420);
        address counterForwarderBaseSepolia = deployer.forwarderAddresses(deployer.counter(), 84532);
        address counterForwarderSepolia = deployer.forwarderAddresses(deployer.counter(), 11155111);

        // Count non-zero addresses
        uint256 nonZeroCount = 0;
        if (counterForwarderArbitrumSepolia != address(0)) nonZeroCount++;
        if (counterForwarderOptimismSepolia != address(0)) nonZeroCount++;
        if (counterForwarderBaseSepolia != address(0)) nonZeroCount++;
        if (counterForwarderSepolia != address(0)) nonZeroCount++;

        vm.startBroadcast(deployerPrivateKey);

        if (counterForwarderArbitrumSepolia != address(0)) {
            gateway.setChainContract(421614, counterForwarderArbitrumSepolia);
            gateway.createPlayer("Account1", vm.envAddress("ACCOUNT1"), 421614);
            console.log("Account1 added to Arbitrum Sepolia");
        } else {
            console.log("Arbitrum Sepolia forwarder not yet deployed");
        }
        if (counterForwarderOptimismSepolia != address(0)) {
            gateway.setChainContract(11155420, counterForwarderOptimismSepolia);
            gateway.createPlayer("Account1", vm.envAddress("ACCOUNT2"), 11155420);
            console.log("Account2 added to Arbitrum Sepolia");
        } else {
            console.log("Optimism Sepolia forwarder not yet deployed");
        }
        if (counterForwarderBaseSepolia != address(0)) {
            gateway.setChainContract(84532, counterForwarderArbitrumSepolia);
            gateway.createPlayer("Account3", vm.envAddress("ACCOUNT3"), 84532);
            console.log("Account3 added to Arbitrum Sepolia");
        } else {
            console.log("Base Sepolia forwarder not yet deployed");
        }
        if (counterForwarderSepolia != address(0)) {
            gateway.setChainContract(11155111, counterForwarderSepolia);
            gateway.createPlayer("Account3", vm.envAddress("ACCOUNT3"), 11155111);
        } else {
            console.log("Sepolia forwarder not yet deployed");
        }

    }
}
