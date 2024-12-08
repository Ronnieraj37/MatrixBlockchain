// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Matrix {
    // Struct to represent a person
    struct Person {
        string name;
        uint8 level;
        address userAddress;
        uint256 chainId;
        bool isActive;
    }

    struct Location {
        uint256 x;
        uint256 y;
    }

    // Struct to represent a map
    struct GameMap {
        mapping(uint256 => Location) personGrid; // Map player ID to their location
    }

    // Struct to represent a message
    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    // State variables
    uint256 public personCount = 1;
    uint256 public mapCount = 1;
    mapping(uint256 => Person) public people;
    mapping(address => uint256) public peopleToID;
    mapping(address => uint256) public playerToMap;
    mapping(uint256 => GameMap) private maps;
    mapping(uint256 => uint256) private objectsInMap;
    // Chat requests and messages
    mapping(address => address[]) public chatRequests;
    mapping(address => mapping(address => bool)) private chatApproved;
    mapping(address => mapping(address => Message[])) private messages;

    // Events
    event ChatRequestCreated(address sender, address receiver);
    event MessageSent(address sender, address receiver, string content);

    // Modifier to validate coordinates within 100x100 bounds
    modifier validCoordinates(uint256 x, uint256 y) {
        require(x < 100 && y < 100, "Coordinates must be within 0-99");
        _;
    }

    // Function to get a map
    function getMap(uint256 mapId) public view returns (Person[] memory, Location[] memory) {
        // Validate the mapId
        require(mapId < mapCount, "Map does not exist");
        uint256 count = objectsInMap[mapId];

        // Create arrays to store people and their locations
        Person[] memory persons = new Person[](count);
        Location[] memory locations = new Location[](count);

        uint256 index = 0;

        // Iterate through all persons and fetch their locations if they are on the specified map
        for (uint256 i = 1; i < personCount; i++) {
            if (playerToMap[people[i].userAddress] == mapId) {
                persons[index] = people[i];
                locations[index] = maps[mapId].personGrid[i]; // Fix indexing
                index++;
            }
        }

        return (persons, locations);
    }

    // Function to create a new map
    function createMap() public returns (uint256) {
        uint256 newMapId = mapCount++;
        return newMapId;
    }

    function createPlayer(string calldata _name, address _userAddress, uint256 _chainId) public {
        Person memory newPerson = Person(_name, 1, _userAddress, _chainId, false);
        people[personCount] = newPerson;
        peopleToID[_userAddress] = personCount;
        personCount++;
    }

    function createObject(string calldata _name, uint256 _chainId) public {
        address randomX = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, block.number)))));
        Person memory newPerson = Person(_name, 0, randomX, _chainId, true);
        people[personCount] = newPerson;
        peopleToID[randomX] = personCount;
        personCount++;
    }

    function addPlayerInMap(address player, uint256 mapId) public {
        require(mapId < mapCount && mapId != 0, "Map does not exist");
        require(peopleToID[player] != 0, "Registration Pending");

        // Assign the player to the map
        playerToMap[player] = mapId;

        // Generate a pseudo-random location within a 100x100 grid
        uint256 randomX = uint256(keccak256(abi.encodePacked(block.timestamp, player, mapId, block.number))) % 100;
        uint256 randomY = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), player, mapId))) % 100;
        objectsInMap[mapId]++;

        uint256 playerId = peopleToID[player];
        // Assign the random location to the player
        maps[mapId].personGrid[playerId] = Location(randomX, randomY);
    }

    // Function to update player's location
    function updatePlayerLocation(uint256 playerId, uint256 x, uint256 y) public validCoordinates(x, y) {
        address playerAddress = people[playerId].userAddress;
        uint256 mapId = playerToMap[playerAddress];
        require(mapId != 0, "Player is not in any map");

        Location memory location = Location(x, y);
        maps[mapId].personGrid[playerId] = location;
    }

    // Function to get a person's details
    function getPersonDetails(uint256 playerId)
        public
        view
        returns (string memory name, uint8 level, uint256 chainId, address userAddress, bool isActive, uint256 mapId)
    {
        Person memory person = people[playerId];
        return (
            person.name,
            person.level,
            person.chainId,
            person.userAddress,
            person.isActive,
            playerToMap[person.userAddress]
        );
    }

    // Function to create a chat request
    function createChatReq(address sender, address receiver) public {
        require(receiver != address(0) || sender != address(0), "invalid params");
        require(people[peopleToID[receiver]].isActive, "User Inactive");

        // Ensure sender and receiver are within proximity
        uint256 senderId = peopleToID[sender];
        uint256 receiverId = peopleToID[receiver];
        uint256 mapId = playerToMap[sender];
        Location memory senderLoc = maps[mapId].personGrid[senderId];
        Location memory receiverLoc = maps[mapId].personGrid[receiverId];

        // Proximity check (2x2 range)
        require(
            abs(int256(senderLoc.x) - int256(receiverLoc.x)) <= 2
                && abs(int256(senderLoc.y) - int256(receiverLoc.y)) <= 2,
            "Players must be within 2x2 range"
        );

        chatRequests[receiver].push(sender);
        emit ChatRequestCreated(sender, receiver);
    }

    // Function to get the sender of a chat request
    function getChatReq(address receiver) public view returns (address[] memory) {
        return chatRequests[receiver];
    }

    // Function to accept a chat request
    function acceptChatReq(address sender) public returns (bool isValid) {
        address[] memory requests = getChatReq(msg.sender);
        for (uint256 i = 0; i < requests.length; i++) {
            if (requests[i] == sender) {
                chatRequests[msg.sender][i] = chatRequests[msg.sender][requests.length - 1];
                delete chatRequests[msg.sender][requests.length - 1];
                chatApproved[msg.sender][sender] = true;
                chatApproved[sender][msg.sender] = true;
                isValid = true;
                break;
            }
        }
        if (!isValid) revert("Invalid!");
    }

    // Function to check if a chat request is approved
    function isChatApproved(address sender, address receiver) public view returns (bool) {
        if (people[peopleToID[receiver]].level == 0) return true;
        return chatApproved[sender][receiver];
    }

    // Function to send a message
    function sendMsg(address sender, address receiver, string memory content) public {
        require(bytes(content).length > 0, "Message cannot be empty");
        require(isChatApproved(sender, receiver), "Unapproved!");

        Message memory newMessage = Message(sender, content, block.timestamp);
        messages[sender][receiver].push(newMessage);
        emit MessageSent(sender, receiver, content);
    }

    function getMsg(address sender, address receiver) public view returns (Message[] memory) {
        // Get messages from sender to receiver
        Message[] memory senderToReceiver = messages[sender][receiver];

        // Get messages from receiver to sender
        Message[] memory receiverToSender = messages[receiver][sender];

        // Create a combined array
        uint256 totalMessages = senderToReceiver.length + receiverToSender.length;
        Message[] memory combinedMessages = new Message[](totalMessages);

        // Copy messages from sender to receiver
        for (uint256 i = 0; i < senderToReceiver.length; i++) {
            combinedMessages[i] = senderToReceiver[i];
        }

        // Copy messages from receiver to sender
        for (uint256 i = 0; i < receiverToSender.length; i++) {
            combinedMessages[senderToReceiver.length + i] = receiverToSender[i];
        }

        // Sort messages by timestamp (Bubble sort for simplicity; can be optimized)
        for (uint256 i = 0; i < combinedMessages.length; i++) {
            for (uint256 j = 0; j < combinedMessages.length - i - 1; j++) {
                if (combinedMessages[j].timestamp > combinedMessages[j + 1].timestamp) {
                    // Swap messages
                    Message memory temp = combinedMessages[j];
                    combinedMessages[j] = combinedMessages[j + 1];
                    combinedMessages[j + 1] = temp;
                }
            }
        }

        return combinedMessages;
    }

    function getCloseProximityPlayers(uint256 mapId) public view returns (uint256[][] memory) {
        // Validate the mapId
        require(mapId < mapCount, "Map does not exist");

        // Store proximity groups
        uint256[][] memory proximityGroups = new uint256[][](personCount);
        bool[] memory visited = new bool[](personCount);
        uint256 groupCount = 0;

        for (uint256 i = 0; i < personCount; i++) {
            if (playerToMap[people[i].userAddress] != mapId || visited[i]) {
                continue;
            }

            // Start a new group for this person
            uint256[] memory group = new uint256[](personCount);
            uint256 groupSize = 0;

            for (uint256 j = i + 1; j < personCount; j++) {
                if (playerToMap[people[j].userAddress] != mapId || visited[j]) {
                    continue;
                }

                // Get the locations of both players
                Location memory loc1 = maps[mapId].personGrid[i];
                Location memory loc2 = maps[mapId].personGrid[j];

                // Check if they are within a 2x2 proximity
                if (abs(int256(loc1.x) - int256(loc2.x)) <= 2 && abs(int256(loc1.y) - int256(loc2.y)) <= 2) {
                    // Add both to the same group
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

    // Function to change the active state of a person
    function setActiveState(uint256 playerId, bool _isActive) public {
        require(playerId > 0 && playerId < personCount, "Invalid player ID");
        people[playerId].isActive = _isActive;
    }

    // Function to get the current map of a player
    function getCurrentMap(address player) public view returns (uint256) {
        return playerToMap[player];
    }

    // Helper function to calculate absolute value of an integer
    function abs(int256 x) private pure returns (uint256) {
        return uint256(x < 0 ? -x : x);
    }
}
