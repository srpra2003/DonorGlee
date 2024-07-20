//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {VRFCoordinatorV2Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/AutomationCompatible.sol";

contract DonorGleeRaffle is Ownable, AutomationCompatibleInterface, VRFConsumerBaseV2{

    constructor(
        address vrfCoordinatorAdd
    ) Ownable(msg.sender) VRFConsumerBaseV2(vrfCoordinatorAdd){
        
    }

    function enterRaffle(address[] memory newPlayers) public {

    }

    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData){

    }

    function performUpkeep(bytes calldata performData) external {

    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        
    }
    
}