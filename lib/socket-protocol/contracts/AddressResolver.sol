// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./interfaces/IAddressResolver.sol";
import {Forwarder} from "./Forwarder.sol";
import {AsyncPromise} from "./AsyncPromise.sol";

import {Ownable} from "./utils/Ownable.sol";

/// @title AddressResolver Contract
/// @notice This contract is responsible for fetching latest core addresses and deploying Forwarder and AsyncPromise contracts.
/// @dev Inherits the Ownable contract and implements the IAddressResolver interface.
contract AddressResolver is Ownable, IAddressResolver {
    IWatcherPrecompile public override watcherPrecompile;
    address public override auctionHouse;
    uint256 public asyncPromiseCounter;

    address[] internal promises;

    bytes public forwarderBytecode = type(Forwarder).creationCode;
    bytes public asyncPromiseBytecode = type(AsyncPromise).creationCode;
    // contracts to gateway map
    mapping(address => address) public override contractsToGateways;
    // gateway to contract map
    mapping(address => address) public override gatewaysToContracts;

    event PlugAdded(address appGateway, uint32 chainSlug, address plug);
    event ForwarderDeployed(address newForwarder, bytes32 salt);
    event AsyncPromiseDeployed(address newAsyncPromise, bytes32 salt);
    error AppGatewayContractAlreadySetByDifferentSender(
        address contractAddress_
    );

    /// @notice Constructor to initialize the AddressResolver contract
    /// @param _owner The address of the contract owner
    /// @param _watcherPrecompile The address of the watcher precompile contract
    constructor(address _owner, address _watcherPrecompile) Ownable(_owner) {
        watcherPrecompile = IWatcherPrecompile(_watcherPrecompile);
    }

    /// @notice Sets the bytecode for the Forwarder contract
    /// @param _forwarderBytecode The bytecode of the Forwarder contract
    function setForwarderBytecode(
        bytes memory _forwarderBytecode
    ) external onlyOwner {
        forwarderBytecode = _forwarderBytecode;
    }

    /// @notice Sets the bytecode for the AsyncPromise contract
    /// @param _asyncPromiseBytecode The bytecode of the AsyncPromise contract
    function setAsyncPromiseBytecode(
        bytes memory _asyncPromiseBytecode
    ) external onlyOwner {
        asyncPromiseBytecode = _asyncPromiseBytecode;
    }

    /// @notice Updates the address of the auction house
    /// @param _auctionHouse The address of the auction house
    function setAuctionHouse(address _auctionHouse) external onlyOwner {
        auctionHouse = _auctionHouse;
    }

    /// @notice Updates the address of the watcher precompile contract
    /// @param _watcherPrecompile The address of the watcher precompile contract
    function setWatcherPrecompile(
        address _watcherPrecompile
    ) external onlyOwner {
        watcherPrecompile = IWatcherPrecompile(_watcherPrecompile);
    }

    /// @notice Gets or deploys a Forwarder contract
    /// @param chainContractAddress_ The address of the chain contract
    /// @param chainSlug_ The chain slug
    /// @return The address of the deployed Forwarder contract
    function getOrDeployForwarderContract(
        address chainContractAddress_,
        uint32 chainSlug_
    ) public returns (address) {
        bytes memory constructorArgs = abi.encode(
            chainSlug_,
            chainContractAddress_,
            address(this)
        );

        bytes memory combinedBytecode = abi.encodePacked(
            forwarderBytecode,
            constructorArgs
        );

        // predict address
        address forwarderAddress = getForwarderAddress(
            chainContractAddress_,
            chainSlug_
        );
        // check if addr has code, if yes, return
        if (forwarderAddress.code.length > 0) {
            return forwarderAddress;
        }

        bytes32 salt = keccak256(constructorArgs);
        address newForwarder;

        assembly {
            newForwarder := create2(
                callvalue(),
                add(combinedBytecode, 0x20),
                mload(combinedBytecode),
                salt
            )
            if iszero(extcodesize(newForwarder)) {
                revert(0, 0)
            }
        }
        emit ForwarderDeployed(newForwarder, salt);
        return newForwarder;
    }

    /// @notice Deploys a Forwarder contract
    /// @param appDeployer_ The address of the app deployer
    /// @param chainContractAddress_ The address of the chain contract
    /// @param chainSlug_ The chain slug
    /// @return The address of the deployed Forwarder contract
    function deployForwarderContract(
        address appDeployer_,
        address chainContractAddress_,
        uint32 chainSlug_
    ) public returns (address) {
        bytes memory constructorArgs = abi.encode(
            chainSlug_,
            chainContractAddress_,
            address(this)
        );

        bytes memory combinedBytecode = abi.encodePacked(
            forwarderBytecode,
            constructorArgs
        );

        bytes32 salt = keccak256(constructorArgs);
        address newForwarder;

        assembly {
            newForwarder := create2(
                callvalue(),
                add(combinedBytecode, 0x20),
                mload(combinedBytecode),
                salt
            )
            if iszero(extcodesize(newForwarder)) {
                revert(0, 0)
            }
        }
        emit ForwarderDeployed(newForwarder, salt);

        address gateway = contractsToGateways[appDeployer_];
        gatewaysToContracts[gateway] = newForwarder;
        contractsToGateways[newForwarder] = gateway;
        return newForwarder;
    }

    /// @notice Deploys an AsyncPromise contract
    /// @param invoker_ The address of the invoker
    /// @return The address of the deployed AsyncPromise contract
    function deployAsyncPromiseContract(
        address invoker_
    ) external returns (address) {
        bytes memory constructorArgs = abi.encode(
            invoker_,
            msg.sender,
            address(this)
        );

        bytes memory combinedBytecode = abi.encodePacked(
            asyncPromiseBytecode,
            constructorArgs
        );

        bytes32 salt = keccak256(
            abi.encodePacked(constructorArgs, asyncPromiseCounter++)
        );

        address newAsyncPromise;
        assembly {
            newAsyncPromise := create2(
                callvalue(),
                add(combinedBytecode, 0x20),
                mload(combinedBytecode),
                salt
            )
            if iszero(extcodesize(newAsyncPromise)) {
                revert(0, 0)
            }
        }

        emit AsyncPromiseDeployed(newAsyncPromise, salt);
        promises.push(newAsyncPromise);
        return newAsyncPromise;
    }

    /// @notice Clears the list of promises
    /// @dev this function helps in queueing the promises and whitelisting on gateway at the end.
    function clearPromises() external {
        delete promises;
    }

    /// @notice Gets the list of promises
    /// @return array of promises deployed while queueing async calls
    function getPromises() external view returns (address[] memory) {
        return promises;
    }

    /// @notice Sets the contract to gateway mapping
    /// @param contractAddress_ The address of the contract
    function setContractsToGateways(address contractAddress_) external {
        if (
            contractsToGateways[contractAddress_] != address(0) &&
            contractsToGateways[contractAddress_] != msg.sender
        ) {
            revert AppGatewayContractAlreadySetByDifferentSender(
                contractAddress_
            );
        }
        contractsToGateways[contractAddress_] = msg.sender;
    }

    /// @notice Gets the predicted address of a Forwarder contract
    /// @param chainContractAddress_ The address of the chain contract
    /// @param chainSlug_ The chain slug
    /// @return The predicted address of the Forwarder contract
    function getForwarderAddress(
        address chainContractAddress_,
        uint32 chainSlug_
    ) public view returns (address) {
        bytes memory constructorArgs = abi.encode(
            chainSlug_,
            chainContractAddress_,
            address(this)
        );
        return
            _predictAddress(
                forwarderBytecode,
                constructorArgs,
                keccak256(constructorArgs)
            );
    }

    /// @notice Gets the predicted address of an AsyncPromise contract
    /// @param invoker_ The address of the invoker
    /// @param forwarder_ The address of the forwarder
    /// @return The predicted address of the AsyncPromise contract
    function getAsyncPromiseAddress(
        address invoker_,
        address forwarder_
    ) public view returns (address) {
        bytes memory constructorArgs = abi.encode(
            invoker_,
            forwarder_,
            address(this)
        );
        return
            _predictAddress(
                asyncPromiseBytecode,
                constructorArgs,
                keccak256(
                    abi.encodePacked(constructorArgs, asyncPromiseCounter)
                )
            );
    }

    /// @notice Predicts the address of a contract
    /// @param bytecode_ The bytecode of the contract
    /// @param constructorArgs_ The constructor arguments of the contract
    /// @param salt_ The salt used for address prediction
    /// @return The predicted address of the contract
    function _predictAddress(
        bytes memory bytecode_,
        bytes memory constructorArgs_,
        bytes32 salt_
    ) internal view returns (address) {
        bytes memory combinedBytecode = abi.encodePacked(
            bytecode_,
            constructorArgs_
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt_,
                keccak256(combinedBytecode)
            )
        );

        return address(uint160(uint256(hash)));
    }
}
