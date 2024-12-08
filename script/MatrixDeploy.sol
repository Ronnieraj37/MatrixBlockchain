// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {GlobalMatrixGateway} from "../src/GlobalMatrixGateway.sol";
import {MatrixDeployer} from "../src/MatrixDeployer.sol";
import {FeesData} from "lib/socket-protocol/contracts/common/Structs.sol";
import {ETH_ADDRESS} from "lib/socket-protocol/contracts/common/Constants.sol";

contract MatrixDeploy is Script {
    function run() external {
        address addressResolver = vm.envAddress("ADDRESS_RESOLVER");

        string memory rpc = vm.envString("SOCKET_RPC");
        vm.createSelectFork(rpc);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Setting fee payment on Arbitrum Sepolia
        FeesData memory feesData = FeesData({feePoolChain: 421614, feePoolToken: ETH_ADDRESS, maxFees: 0.01 ether});

        MatrixDeployer deployer = new MatrixDeployer(addressResolver, feesData);

        GlobalMatrixGateway gateway = new GlobalMatrixGateway(addressResolver, address(deployer), feesData);

        console.log("Contracts deployed:");
        console.log("MatrixDeployer:", address(deployer));
        console.log("GlobalMatrixGateway:", address(gateway));
    }
}
