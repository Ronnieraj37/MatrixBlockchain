// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "socket-protocol/contracts/utils/Ownable.sol";

contract ChainMatrix is Ownable(msg.sender) {

    address public socket;

    modifier onlySocket() {
        require(msg.sender == socket, "not socket");
        _;
    }

    function setSocket(address _socket) external onlyOwner {
        socket = _socket;
    }

    struct Person {
        string name;
        uint8 level;
        address userAddress;
        uint256 chainId;
        bool isActive;
    }

    struct Message {
        address sender;
        string content;
        uint256 timestamp;
    }

    uint256 public playersOnChain;
    mapping(address => Person) public playerChainData;
    // State variables
    mapping(address => mapping(address => Message[])) private messages; // Messages specific to this chain

    // Events
    event MessageSent(address sender, address receiver, string content);

    // Function to register a player on this chain (called by GlobalMatrix)
    function registerPlayer(string calldata _name, address _userAddress, uint256 _chainId) onlySocket external {
        Person memory newPerson = Person(_name, 1, _userAddress, _chainId, false);
        playerChainData[_userAddress] = newPerson;
        playersOnChain++;
    }

    function registerObject(string calldata _name, address _userAddress, uint256 _chainId) onlySocket external {
        Person memory newPerson = Person(_name, 0, _userAddress, _chainId, true);
        playerChainData[_userAddress] = newPerson;
        playersOnChain++;
    }
    
    // Function to send a message on this chain
    function addMsg(address sender, address receiver, string memory content) onlySocket external {
        require(bytes(content).length > 0, "Message cannot be empty");

        messages[sender][receiver].push(Message(sender, content, block.timestamp));
        emit MessageSent(sender, receiver, content);
    }

    // Function to get chat messages between two players on this chain
    function getChatMessages(address sender, address receiver) external view returns (Message[] memory) {
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

    function getPlayersOnChain() external view returns (uint256) {
        return playersOnChain;
    }
}
