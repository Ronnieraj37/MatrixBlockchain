// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../../utils/Ownable.sol";

contract Counter is Ownable(msg.sender) {
    address public socket;
    uint256 public counter;

    modifier onlySocket() {
        require(msg.sender == socket, "not socket");
        _;
    }

    function setSocket(address _socket) external onlyOwner {
        socket = _socket;
    }

    function setCounter(uint256 _counter) external onlySocket {
        counter = _counter;
    }
}
