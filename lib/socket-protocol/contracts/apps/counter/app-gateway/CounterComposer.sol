// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../../../base/AppGatewayBase.sol";
import "../Counter.sol";
import "../../../utils/Ownable.sol";

contract CounterComposer is AppGatewayBase, Ownable {
    constructor(
        address _addressResolver,
        address deployerContract_,
        FeesData memory feesData_
    ) AppGatewayBase(_addressResolver) Ownable(msg.sender) {
        addressResolver.setContractsToGateways(deployerContract_);
        _setFeesData(feesData_);
    }

    // function incrementCounters(address[] calldata _instance, uint256 _counter) public queueAndExecute {
    //     for (uint256 i = 0; i < _instance.length; i++) {
    //         Counter(_instance[i]).setCounter(_counter);
    //     }
    // }

    function incrementCounter(
        address _instance,
        uint256 _counter
    ) public async {
        Counter(_instance).setCounter(_counter);
    }
}
