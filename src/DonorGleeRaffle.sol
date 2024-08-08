//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {VRFCoordinatorV2Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/AutomationCompatible.sol";

contract DonorGleeRaffle is Ownable, AutomationCompatibleInterface, VRFConsumerBaseV2 {
    //////////////////////////
    ///////  ERRORS   ////////
    //////////////////////////
    error DonorGleeRaffle__RaffleIsCALCULATING();
    error DonorGleeRaffle__NoUpkeepNeeded();
    error DonorGleeRaffle__TransferFailed();

    ////////////////////////////////
    ////// TYPE DECLARATIONS ///////
    ////////////////////////////////
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    ////////////////////////////////
    //////  STATE VARIABLES  ///////
    ////////////////////////////////
    uint16 private constant MINIMUM_CONFIRNATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_raffleInterval;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint64 private immutable i_subId;
    uint256 private s_prizePool;
    address[] private s_players;
    RaffleState private s_state;
    uint256 private s_lastWinTime;
    mapping(address player => bool uniqueness) private s_doesExist;
    VRFCoordinatorV2Interface private vrfCoordinator;

    //////////////////////////
    ///////  EVENTS   ////////
    //////////////////////////
    event RaffleEntered(address[] players, uint256 raffleEnteredAmount);
    event WinnerRequsted(uint256 indexed requestId);
    event WinnerPlayerDeclared(address indexed winnerPlayer, uint256 indexed requestId, uint256 winAmount);

    //////////////////////////
    /////// FUNCTIONS ////////
    //////////////////////////
    constructor(
        address vrfCoordinatorAdd,
        uint256 raffleInterval,
        bytes32 keyHash,
        uint64 subId,
        uint32 callbackGasLimit
    ) Ownable(msg.sender) VRFConsumerBaseV2(vrfCoordinatorAdd) {
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorAdd);
        i_keyHash = keyHash;
        i_callbackGasLimit = callbackGasLimit;
        i_subId = subId;
        i_raffleInterval = raffleInterval * (1 days);
        s_state = RaffleState.OPEN;
        s_prizePool = 0;
        s_lastWinTime = block.timestamp;
    }

    function enterRaffle(address[] memory newPlayers) public payable onlyOwner {
        if (s_state == RaffleState.CALCULATING) {
            revert DonorGleeRaffle__RaffleIsCALCULATING();
        }

        for (uint256 i = 0; i < newPlayers.length; i++) {
            if (!s_doesExist[newPlayers[i]]) {
                s_players.push(newPlayers[i]);
                s_doesExist[newPlayers[i]] = true;
            }
        }

        s_prizePool += msg.value;
        emit RaffleEntered(newPlayers, msg.value);
    }

    function checkUpkeep(bytes memory /*checkData*/ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData*/ )
    {
        bool isTime = (block.timestamp - s_lastWinTime >= i_raffleInterval);
        bool hasPlayers = (s_players.length > 0);
        bool hasMoney = (s_prizePool > 0);
        bool isOpen = (s_state == RaffleState.OPEN);

        upkeepNeeded = (isTime && hasMoney && hasPlayers && isOpen);

        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /*performData*/ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert DonorGleeRaffle__NoUpkeepNeeded();
        }

        s_state = RaffleState.CALCULATING;
        uint256 requestId =
            vrfCoordinator.requestRandomWords(i_keyHash, i_subId, MINIMUM_CONFIRNATIONS, i_callbackGasLimit, NUM_WORDS);

        emit WinnerRequsted(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winnerPlayer = payable(s_players[winnerIndex]);
        uint256 winAmount = s_prizePool;
        s_prizePool = 0;
        s_players = new address[](0);
        s_lastWinTime = block.timestamp;
        s_state = RaffleState.OPEN;

        emit WinnerPlayerDeclared(winnerPlayer, requestId, winAmount);

        (bool callSuccess,) = winnerPlayer.call{value: winAmount}("");
        if (!callSuccess) {
            revert DonorGleeRaffle__TransferFailed();
        }
    }

    function getRaffleStatus() public view returns (RaffleState) {
        return s_state;
    }

    function getRaffleInterval() public view returns (uint256) {
        return i_raffleInterval;
    }

    function getOwner() public view returns (address) {
        return owner();
    }

    function getConstructorArgs() public view returns (address, uint256, bytes32, uint64, uint32) {
        return (address(vrfCoordinator), i_raffleInterval, i_keyHash, i_subId, i_callbackGasLimit);
    }

    function getTotalPlayersInCurrentRaffle() public view returns (uint256) {
        return s_players.length;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getLastWinTime() public view returns (uint256) {
        return s_lastWinTime;
    }
}
