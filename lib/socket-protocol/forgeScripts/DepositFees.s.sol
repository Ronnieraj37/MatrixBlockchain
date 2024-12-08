// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Console.sol";
import {PayloadDeliveryPlug} from "../contracts/apps/payload-delivery/PayloadDeliveryPlug.sol";
import {FeesData} from "../contracts/common/Structs.sol";
import {ETH_ADDRESS} from "../contracts/common/Constants.sol";

contract DepositFees is Script {
    function run() external {
        vm.startBroadcast();
        PayloadDeliveryPlug feesManager = PayloadDeliveryPlug(
            0x804Af74b5b3865872bEf354e286124253782FA95
        );
        address appGateway = 0xb1F4CbFCE786aA8B553796Fb06c04Dd461967A16;
        address appDeployer = 0x02520426a04D2943d817A60ABa37ab25bA10e630;
        uint feesAmount = 0.01 ether;
        feesManager.deposit{value: feesAmount}(
            ETH_ADDRESS,
            feesAmount,
            appGateway
        );
        feesManager.deposit{value: feesAmount}(
            ETH_ADDRESS,
            feesAmount,
            appDeployer
        );
    }
}
