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
    error DonorGleeFund__InvalidDonation();
    error DonorGleeFund__InvalidActiveTime();


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
        bool isPromoted;
        DonationStatus status;
    }


    ////////////////////////////////
    //////  STATE VARIABLES  ///////
    ////////////////////////////////
    uint256 private immutable i_maxDonationInterval;
    uint256 private immutable i_raffleEntryInterval;
    uint256 private s_donationCount;
    uint256 private s_platformFunds;
    uint256 private s_lastRaffleEntry;
    uint256 private s_raffleFund;
    mapping(uint256 donationId => Donation donation) private s_donations;
    address[] private s_rafflePlayers;
    mapping(address wallets => bool isWhiteListed) private s_whiteList;



    //////////////////////////
    ///////  EVENTS   ////////
    //////////////////////////

    event DonationCreated(address indexed creator, address indexed wallet, uint256 donationId);


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
            revert DonorGleeFund__InvalidDonation();
        }
        _;
    }

    modifier ValidActiveTime(uint256 activeTime){
        if(activeTime > i_maxDonationInterval){
            revert DonorGleeFund__InvalidActiveTime();
        }
        _;
    }


    //////////////////////////
    /////// FUNCTIONS ////////
    //////////////////////////

    constructor(uint256 _maxDonationInterval, uint256 _raffleEntryInterval) Ownable(msg.sender) {
        i_maxDonationInterval = _maxDonationInterval;
        i_raffleEntryInterval = _raffleEntryInterval * (1 days);
        s_donationCount = 0;
        s_lastRaffleEntry = block.timestamp;
        s_platformFunds = 0;
    }

    function createDonation(string memory _name, string memory _description, address _walletAdd, uint256 _goal, uint256 _activeTime) public ValidAmount(_goal) ValidAddress(_walletAdd) ValidActiveTime(_activeTime){

        Donation memory newDonation = s_donations[s_donationCount];
        newDonation.donationId = s_donationCount;
        newDonation.name = _name;
        newDonation.description = _description;
        newDonation.creator = msg.sender;
        newDonation.funds = 0;
        newDonation.walletAdd = _walletAdd;
        newDonation.goal = _goal;
        newDonation.activeTime = _activeTime*(1 days);
        newDonation.isPromoted = s_whiteList[_walletAdd];
        newDonation.status = DonationStatus.OPEN;

        s_donationCount++;
        emit DonationCreated(msg.sender,_walletAdd,newDonation.donationId);

    }

    function fundDonation(uint256 donationId) public payable ValidDonation(donationId) ValidAmount(msg.value){

    }

    function redeemDonation(uint256 donationId) public ValidDonation(donationId) {

    }

    function fundPlatformCreator() public payable ValidAmount(msg.value) {

    }

    function reedeemPlatformCreatorFunds() public ValidAmount(s_platformFunds) {

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