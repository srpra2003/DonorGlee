// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions




//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {AutomationCompatibleInterface} from "@chainlink/v0.8/interfaces/AutomationCompatibleInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @title DonorGleeFund
 * @author Sohamkumar Prajapati - smrp1720@gmail.com
 * @notice This is the Funding Contract where Funds to the donations is managed and raised and
 *         the raffle system is also managed here
 */

contract DonorGleeFund is AutomationCompatibleInterface, Ownable {

    //////////////////////////
    ///////  ERRORS   ////////
    //////////////////////////
    error DonorGleeFund__InvalidAmount();
    error DonorGleeFund__InvaidAddress();
    error DonationGleeFund__InvalidDonation();


    ////////////////////////////////
    ////// TYPE DECLARATIONS ///////
    ////////////////////////////////
    enum DonationStatus{
        OPEN,
        EXPIRED
    }
    struct Donation{
        uint256 donationId;
        string name;
        string description;
        address creator;
        address walletAdd;
        uint256 funds;
        uint256 goal;
        uint256 activeTime;
        DonationStatus status;
    }


    ////////////////////////////////
    //////  STATE VARIABLES  ///////
    ////////////////////////////////
    uint256 private immutable i_maxDonationInterval;
    uint256 private immutable i_raffleEntryInterval;
    uint256 private s_donationCount;
    uint256 private s_platformDonation;
    uint256 private s_lastRaffleEntry;
    uint256 private s_raffleFund;
    Donation[] private s_donations;
    address[] private s_rafflePlayers;
    address[] private whiteList;


    //////////////////////////
    /////// MODIFIERS ////////
    //////////////////////////
    modifier ValidAmount(uint256 amount){
        if(amount == 0){
            revert DonorGleeFund__InvalidAmount();
        }
        _;
    }

    modifier ValidAddress(address add){
        if(add == address(0)){
            revert DonorGleeFund__InvaidAddress();
        }
        _;
    }

    modifier ValidDonation(uint256 id){
        if(id >= s_donationCount){
            revert DonationGleeFund__InvalidDonation();
        }
        _;
    }


    //////////////////////////
    /////// FUNCTIONS ////////
    //////////////////////////

    constructor(uint256 _maxDonationInterval, uint256 _raffleEntryInterval) Ownable(msg.sender) {
        i_maxDonationInterval = _maxDonationInterval;
        i_raffleEntryInterval = _raffleEntryInterval;
        s_donationCount = 0;
        s_lastRaffleEntry = block.timestamp;
        s_platformDonation = 0;
    }

    function createDonation(string memory _name, string memory _description, address _walletAdd, uint256 _goal, uint256 _activeTime) public ValidAmount(_goal) ValidAddress(_walletAdd) {

    }

    function fundDonation(uint256 donationId) public payable ValidDonation(donationId) ValidAmount(msg.value){

    }

    function redeemDonation(uint256 donationId) public ValidDonation(donationId) {

    }

    function fundPlatformCreator() public payable ValidAmount(msg.value) {

    }

    function reedeemPlatformCreatorFunds() public ValidAmount(s_platformDonation) {

    }
    
    function addWalletToWhiteList(address wallet) public ValidAddress(wallet) {

    }

    function removeWalletFromWhiteList(address wallet) public ValidAddress(wallet) {

    }

    function closeExpireDonations() public {

    }

    function checkUpkeep(bytes calldata /*checkData*/) external returns (bool upkeepNeeded, bytes memory /*performData*/){

    }

    function performUpkeep(bytes calldata /*performData*/) external {

    }
}