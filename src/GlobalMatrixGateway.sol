// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "socket-protocol/contracts/base/AppGatewayBase.sol";
import "./ChainMatrix.sol";

contract GlobalMatrixGateway is AppGatewayBase {
    struct Location {
        uint256 x;
        uint256 y;
    }

    struct GameMap {
        mapping(address => Location) personGrid; // Map player ID to their location
    }

    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    uint256 public personCount = 1;
    uint256 public mapCount = 1;
    mapping(address => uint256) public playerToMap;
    mapping(address => string) public playerImage;
    mapping(uint256 => address[]) public mapToPlayers;
    mapping(address => uint256) public playerChainId; // Mapping from player address to their chainId
    mapping(uint256 => GameMap) private maps;
    mapping(uint256 => address) private objectsInMap;

    // Chain-specific contract references
    mapping(uint256 => address) public chainContracts; // Mapping from chainId to chain contract address

    // Events
    event PlayerAdded(address player, uint256 chainId);
    event MessageSent(address sender, address receiver, string content);

    constructor(
        address _addressResolver,
        address deployerContract_,
        FeesData memory feesData_
    ) AppGatewayBase(_addressResolver) {
        addressResolver.setContractsToGateways(deployerContract_);
        _setFeesData(feesData_);
    }

    function setFees(FeesData memory feesData_) public {
        feesData = feesData_;
    }

    // Set the contract address for a specific chain
    function setChainContract(uint256 chainId, address chainContract) external {
        chainContracts[chainId] = chainContract;
    }

    // Function to create a new map
    function createMap() public returns (uint256) {
        uint256 newMapId = mapCount++;
        return newMapId;
    }

    // Function to create a player on the global Matrix
    function createPlayer(
        string calldata _name,
        address _userAddress,
        uint256 _chainId
    ) public async {
        playerChainId[_userAddress] = _chainId;
        personCount++;
        // Call ChainMatrix to register the player
        ChainMatrix(chainContracts[_chainId]).registerPlayer(
            _name,
            _userAddress,
            _chainId
        );
    }

    function createObject(
        string calldata _name,
        uint256 _chainId
    ) public async {
        address randomX = address(
            uint160(
                uint256(
                    keccak256(abi.encodePacked(block.timestamp, block.number))
                )
            )
        );
        playerChainId[randomX] = _chainId;
        personCount++;
        // Call ChainMatrix to register the object
        ChainMatrix(chainContracts[_chainId]).registerObject(
            _name,
            randomX,
            _chainId
        );
    }

    function addPlayerInMap(address player, uint256 mapId) public {
        require(mapId < mapCount && mapId != 0, "Map does not exist");
        require(playerChainId[player] != 0, "Registration Pending");

        // Assign the player to the map
        playerToMap[player] = mapId;

        // Generate a pseudo-random location within a 100x100 grid
        uint256 randomX = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, player, mapId, block.number)
            )
        ) % 100;
        uint256 randomY = uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), player, mapId)
            )
        ) % 100;

        updatePlayerLocation(player, randomX, randomY);
    }

    function setPlayerImage(address player, string calldata imageURL) public {
        playerImage[player] = imageURL;
    }

    // Function to update the player's location globally (called by the chain-specific contract)
    function updatePlayerLocation(
        address playerAddress,
        uint256 x,
        uint256 y
    ) public {
        uint256 mapId = playerToMap[playerAddress];
        require(mapId != 0, "Player is not in any map");
        mapToPlayers[mapId].push(playerAddress);
        Location memory location = Location(x, y);
        maps[mapId].personGrid[playerAddress] = location;
    }

    // Function to send a message globally (called by the chain-specific contract)
    function sendMessage(
        address sender,
        address receiver,
        string memory content
    ) external async {
        uint256 senderChainId = playerChainId[sender];
        uint256 receiverChainId = playerChainId[receiver];

        // Get the sender's and receiver's location
        (uint256 senderX, uint256 senderY) = getPlayerLocation(sender);
        (uint256 receiverX, uint256 receiverY) = getPlayerLocation(receiver);

        // Ensure players are within the 2x2 range on their respective maps (100x100 matrix)
        require(
            (senderX >= receiverX - 2 && senderX <= receiverX + 2) &&
                (senderY >= receiverY - 2 && senderY <= receiverY + 2),
            "Players are too far apart"
        );

        emit MessageSent(sender, receiver, content);

        // Store the message on both ChainMatrix contracts
        ChainMatrix(chainContracts[senderChainId]).addMsg(
            sender,
            receiver,
            content
        );
        ChainMatrix(chainContracts[receiverChainId]).addMsg(
            sender,
            receiver,
            content
        );
    }

    // Helper function to get a player's location on the given chain
    function getPlayerLocation(
        address player
    ) public view returns (uint256 x, uint256 y) {
        uint256 mapId = playerToMap[player];
        Location memory location = maps[mapId].personGrid[player];
        return (location.x, location.y);
    }

    function getCloseProximityPlayers(
        uint256 mapId
    ) public view returns (uint256[][] memory) {
        // Validate the mapId
        require(mapId < mapCount, "Map does not exist");

        // Store proximity groups
        uint256[][] memory proximityGroups = new uint256[][](personCount);
        bool[] memory visited = new bool[](personCount);
        uint256 groupCount = 0;

        // Get all players in the map
        address[] memory playersInMap = mapToPlayers[mapId];

        // Iterate through all players in the map
        for (uint256 i = 0; i < playersInMap.length; i++) {
            address playerA = playersInMap[i];

            if (visited[i]) continue;

            // Start a new group for this player
            uint256[] memory group = new uint256[](personCount);
            uint256 groupSize = 0;

            // Check for close proximity with other players
            for (uint256 j = i + 1; j < playersInMap.length; j++) {
                address playerB = playersInMap[j];

                if (visited[j]) continue;

                // Get the locations of both players using getPlayerLocation function
                (uint256 locAx, uint256 locAy) = getPlayerLocation(playerA);
                (uint256 locBx, uint256 locBy) = getPlayerLocation(playerB);

                // Check if they are within a 2x2 proximity
                if (
                    abs(int256(locAx) - int256(locBx)) <= 2 &&
                    abs(int256(locAy) - int256(locBy)) <= 2
                ) {
                    // Add both players to the same group
                    group[groupSize++] = i;
                    group[groupSize++] = j;
                    visited[j] = true;
                }
            }

            // If we found a group, save it
            if (groupSize > 0) {
                // Resize the group array to fit the actual group size
                uint256[] memory trimmedGroup = new uint256[](groupSize);
                for (uint256 k = 0; k < groupSize; k++) {
                    trimmedGroup[k] = group[k];
                }
                proximityGroups[groupCount++] = trimmedGroup;
            }
        }

        // Resize the proximityGroups array to fit the actual number of groups
        uint256[][] memory trimmedGroups = new uint256[][](groupCount);
        for (uint256 i = 0; i < groupCount; i++) {
            trimmedGroups[i] = proximityGroups[i];
        }

        return trimmedGroups;
    }

    // Function to get a map
    function getMap(
        uint256 mapId
    ) public view returns (address[] memory, Location[] memory) {
        // Validate the mapId
        require(mapId < mapCount, "Map does not exist");

        // Get all players in the map
        address[] memory playersInMap = mapToPlayers[mapId];

        // Prepare arrays for storing player addresses and their respective locations
        address[] memory userAddresses = new address[](playersInMap.length);
        Location[] memory locations = new Location[](playersInMap.length);

        // Populate the arrays with player addresses and their locations
        for (uint256 i = 0; i < playersInMap.length; i++) {
            address player = playersInMap[i];

            // Get the player's location using getPlayerLocation function
            (uint256 x, uint256 y) = getPlayerLocation(player);

            // Store the player address and location in the arrays
            userAddresses[i] = player;
            locations[i] = Location(x, y);
        }

        return (userAddresses, locations);
    }

    // Helper function to calculate absolute value of an integer
    function abs(int256 x) private pure returns (uint256) {
        return uint256(x < 0 ? -x : x);
    }
}
