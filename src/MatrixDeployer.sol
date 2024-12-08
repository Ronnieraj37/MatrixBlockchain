// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./ChainMatrix.sol";
import "socket-protocol/contracts/base/AppDeployerBase.sol";

contract MatrixDeployer is AppDeployerBase {
    bytes32 public counter = _createContractId("chainMatrix");

    constructor(address addressResolver_, FeesData memory feesData_) AppDeployerBase(addressResolver_) {
        creationCodeWithArgs[counter] = type(ChainMatrix).creationCode;
        _setFeesData(feesData_);
    }

    function deployContracts(uint32 chainSlug) external async {
        _deploy(counter, chainSlug);
    }

    function initialize(uint32 chainSlug) public override async {
        address socket = getSocketAddress(chainSlug);
        address counterForwarder = forwarderAddresses[counter][chainSlug];
        ChainMatrix(counterForwarder).setSocket(socket);
    }

    function setFees(FeesData memory feesData_) public {
        feesData = feesData_;
    }
}
