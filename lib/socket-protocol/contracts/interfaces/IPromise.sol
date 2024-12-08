// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IPromise {
    function then(
        bytes4 selector,
        bytes memory data
    ) external returns (address promise_);

    function markResolved(bytes memory returnData) external;
}
