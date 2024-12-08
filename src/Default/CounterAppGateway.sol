// // SPDX-License-Identifier: GPL-3.0
// pragma solidity >=0.7.0 <0.9.0;

// import "socket-protocol/contracts/base/AppGatewayBase.sol";
// import "./Counter.sol";

// contract CounterAppGateway is AppGatewayBase {
//     constructor(address _addressResolver, address deployerContract_, FeesData memory feesData_)
//         AppGatewayBase(_addressResolver)
//     {
//         addressResolver.setContractsToGateways(deployerContract_);
//         _setFeesData(feesData_);
//     }

//     function incrementCounters(address[] memory instances) public async {
//         // the increase function is called on given list of instances
//         // this
//         for (uint256 i = 0; i < instances.length; i++) {
//             Counter(instances[i]).increase();
//         }
//     }

//     function setFees(FeesData memory feesData_) public {
//         feesData = feesData_;
//     }
// }
