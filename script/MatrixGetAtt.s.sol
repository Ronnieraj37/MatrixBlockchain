// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MatrixDeployer} from "../src/MatrixDeployer.sol";
import {ChainMatrix} from "../src/ChainMatrix.sol";

contract GetMatrixAttributes is Script {
    // bytes32 public counter = keccak256(abi.encode("counter"));

    function run() external {
        MatrixDeployer deployer = MatrixDeployer(
            vm.envAddress("COUNTER_DEPLOYER")
        );

        vm.createSelectFork(vm.envString("SOCKET_RPC"));
        address counterInstanceArbitrumSepolia = deployer.getOnChainAddress(
            deployer.counter(),
            421614
        );
        address counterInstanceOptimismSepolia = deployer.getOnChainAddress(
            deployer.counter(),
            11155420
        );
        address counterInstanceBaseSepolia = deployer.getOnChainAddress(
            deployer.counter(),
            84532
        );

        if (counterInstanceArbitrumSepolia != address(0)) {
            vm.createSelectFork(vm.envString("ARBITRUM_SEPOLIA_RPC"));
            uint256 counterValueArbitrumSepolia = ChainMatrix(
                counterInstanceArbitrumSepolia
            ).getPlayersOnChain();
            console.log(
                counterInstanceArbitrumSepolia,
                "ChainMatrix value on Arbitrum Sepolia: ",
                counterValueArbitrumSepolia
            );
        } else {
            console.log("ChainMatrix not yet deployed on Arbitrum Sepolia");
        }

        if (counterInstanceOptimismSepolia != address(0)) {
            vm.createSelectFork(vm.envString("OPTIMISM_SEPOLIA_RPC"));
            uint256 counterValueOptimismSepolia = ChainMatrix(
                counterInstanceOptimismSepolia
            ).getPlayersOnChain();
            console.log(
                counterInstanceOptimismSepolia,
                "ChainMatrix value on Optimism Sepolia: ",
                counterValueOptimismSepolia
            );
        } else {
            console.log("ChainMatrix not yet deployed on Optimism Sepolia");
        }

        if (counterInstanceBaseSepolia != address(0)) {
            vm.createSelectFork(vm.envString("BASE_SEPOLIA_RPC"));
            uint256 counterValueBaseSepolia = ChainMatrix(
                counterInstanceBaseSepolia
            ).getPlayersOnChain();
            console.log(
                counterInstanceBaseSepolia,
                "ChainMatrix value on Base Sepolia: ",
                counterValueBaseSepolia
            );
        } else {
            console.log("ChainMatrix not yet deployed on Base Sepolia");
        }
    }
}
