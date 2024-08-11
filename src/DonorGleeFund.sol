//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {AutomationCompatibleInterface} from "@chainlink/v0.8/interfaces/AutomationCompatibleInterface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {DonorGleeRaffle} from "./DonorGleeRaffle.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DonorGleeFund
 * @author Sohamkumar Prajapati - smrp1720@gmail.com
 * @notice This is the Funding Contract where Funds to the donations is managed and raised and
 *         the raffle system is also managed here
 */
contract DonorGleeFund is AutomationCompatibleInterface, Ownable, ReentrancyGuard {
    //////////////////////////
    ///////  ERRORS   ////////
    //////////////////////////
    error DonorGleeFund__InvalidAmount();
    error DonorGleeFund__InvaidAddress();
    error DonorGleeFund__InvalidDonation();
    error DonorGleeFund__InvalidActiveTime();
    error DonorGleeFund__TransferFailed();
    error DonorGleeFund__IllegealAccessToDonation(address);
    error DonorGleeFund__DonationSessionIsExpired();
    error DonorGleeFund__AccessToRaffleContractStateFailed();
    error DonorGleeFund__NoUpkeepNeeded();

    ////////////////////////////////
    ////// TYPE DECLARATIONS ///////
    ////////////////////////////////
    enum DonationStatus {
        OPEN,
        EXPIRED
    }

    struct Donation {
        uint256 donationId;
        string name;
        string description;
        address creator;
        address walletAdd;
        uint256 funds;
        uint256 goal;
        uint256 creationTime;
        uint256 activeTime;
        bool isPromoted;
        DonationStatus status;
    }

    ////////////////////////////////
    //////  STATE VARIABLES  ///////
    ////////////////////////////////
    uint256 private immutable i_maxDonationInterval;
    uint256 private immutable i_raffleEntryInterval;
    address private immutable i_raffleContract;
    uint256 private s_donationCount;
    uint256 private s_platformFunds;
    uint256 private s_lastRaffleEntry;
    uint256 private s_prizePool;
    uint256 private s_cntWhiteListedWallets;
    address[] private s_rafflePlayers;
    mapping(uint256 donationId => Donation donation) private s_donations;
    mapping(address wallets => bool isWhiteListed) private s_whiteList;

    //////////////////////////
    ///////  EVENTS   ////////
    //////////////////////////

    event DonationCreated(address indexed creator, address indexed wallet, uint256 donationId);
    event DonationRaised(uint256 donationId, address indexed donor);
    event DonationWithdrawn(address indexed creator, uint256 donationId, uint256 timeStamp, uint256 withdrawAmount);
    event WalletWhiteListed(address indexed wallet);
    event WalletRemovedFromWhiteList(address indexed wallet);
    event DonationExpired(uint256 indexed donationId, uint256 timeStamp);
    event PlatformFunded(address indexed donor, uint256 indexed donationAmount, uint256 timeStamp);
    event PlatformFundWithDrawed(uint256 withdrawedAmount);

    //////////////////////////
    /////// MODIFIERS ////////
    //////////////////////////
    modifier ValidAmount(uint256 amount) {
        if (amount == 0) {
            revert DonorGleeFund__InvalidAmount();
        }
        _;
    }

    modifier ValidAddress(address add) {
        if (add == address(0)) {
            revert DonorGleeFund__InvaidAddress();
        }
        _;
    }

    modifier ValidDonation(uint256 id) {
        if (id >= s_donationCount) {
            revert DonorGleeFund__InvalidDonation();
        }
        _;
    }

    //////////////////////////
    /////// FUNCTIONS ////////
    //////////////////////////

    constructor(uint256 _maxDonationInterval, uint256 _raffleEntryInterval, address _raffleContract)
        Ownable(msg.sender)
    {
        i_raffleContract = _raffleContract;
        i_maxDonationInterval = _maxDonationInterval;
        i_raffleEntryInterval = _raffleEntryInterval * (1 days);
        s_donationCount = 0;
        s_lastRaffleEntry = block.timestamp;
        s_platformFunds = 0;
        s_cntWhiteListedWallets = 0;
    }

    function createDonation(
        string memory _name,
        string memory _description,
        address _walletAdd,
        uint256 _goal,
        uint256 _activeTime
    ) public ValidAmount(_goal) ValidAddress(_walletAdd) returns (uint256) {
        if (_activeTime > i_maxDonationInterval) {
            revert DonorGleeFund__InvalidActiveTime();
        }

        Donation memory newDonation = s_donations[s_donationCount];
        newDonation.donationId = s_donationCount;
        newDonation.name = _name;
        newDonation.description = _description;
        newDonation.creator = msg.sender;
        newDonation.funds = 0;
        newDonation.walletAdd = _walletAdd;
        newDonation.goal = _goal;
        newDonation.creationTime = block.timestamp;
        newDonation.activeTime = _activeTime * (1 days);
        newDonation.isPromoted = s_whiteList[_walletAdd];
        newDonation.status = DonationStatus.OPEN;

        s_donations[s_donationCount] = newDonation;

        s_donationCount++;
        emit DonationCreated(msg.sender, _walletAdd, newDonation.donationId);

        return newDonation.donationId;
    }

    function fundDonation(uint256 donationId) public payable ValidDonation(donationId) ValidAmount(msg.value) {
        if (s_donations[donationId].status == DonationStatus.EXPIRED) {
            revert DonorGleeFund__DonationSessionIsExpired();
        }

        uint256 _actualFund = (msg.value * 98) / 100;
        uint256 _raffleContro = (msg.value * 2) / 100;

        s_prizePool += _raffleContro;
        s_rafflePlayers.push(msg.sender);
        s_donations[donationId].funds += _actualFund;

        emit DonationRaised(donationId, msg.sender);
    }

    function redeemDonation(uint256 donationId)
        public
        ValidDonation(donationId)
        ValidAmount(s_donations[donationId].funds)
        nonReentrant
    {
        if (msg.sender != s_donations[donationId].creator) {
            revert DonorGleeFund__IllegealAccessToDonation(msg.sender);
        }

        uint256 _fundToWithdraw = s_donations[donationId].funds;
        s_donations[donationId].funds = 0;
        emit DonationWithdrawn(msg.sender, donationId, block.timestamp, _fundToWithdraw);

        (bool callSuccess,) = payable(s_donations[donationId].walletAdd).call{value: _fundToWithdraw}("");
        if (!callSuccess) {
            revert DonorGleeFund__TransferFailed();
        }
    }

    function fundPlatformCreator() public payable ValidAmount(msg.value) {
        uint256 _actualFund = (msg.value * 98) / 100;
        uint256 _raffleContro = (msg.value * 2) / 100;

        s_prizePool += _raffleContro;
        s_rafflePlayers.push(msg.sender);
        s_platformFunds += _actualFund;
        emit PlatformFunded(msg.sender, _actualFund, block.timestamp);
    }

    function reedeemPlatformCreatorFunds() public ValidAmount(s_platformFunds) onlyOwner {
        uint256 fundsToTransfer = s_platformFunds;
        s_platformFunds = 0;
        emit PlatformFundWithDrawed(fundsToTransfer);

        (bool callSuccess,) = payable(owner()).call{value: fundsToTransfer}("");
        if (!callSuccess) {
            revert DonorGleeFund__TransferFailed();
        }
    }

    function addWalletToWhiteList(address wallet) public ValidAddress(wallet) onlyOwner {
        if (s_whiteList[wallet] == true) {
            return;
        }

        s_whiteList[wallet] = true;
        s_cntWhiteListedWallets++;
        for (uint256 i = 0; i < s_donationCount; i++) {
            if (s_donations[i].walletAdd == wallet) {
                s_donations[i].isPromoted = true;
            }
        }
        emit WalletWhiteListed(wallet);
    }

    function removeWalletFromWhiteList(address wallet) public ValidAddress(wallet) onlyOwner {
        if (s_whiteList[wallet] == false) {
            return;
        }

        s_whiteList[wallet] = false;
        s_cntWhiteListedWallets--;
        for (uint256 i = 0; i < s_donationCount; i++) {
            if (s_donations[i].walletAdd == wallet) {
                s_donations[i].isPromoted = false;
            }
        }
        emit WalletRemovedFromWhiteList(wallet);
    }

    function closeExpireDonations() public {
        for (uint256 i = 0; i < s_donationCount; i++) {
            if (block.timestamp - s_donations[i].creationTime >= s_donations[i].activeTime) {
                s_donations[i].status = DonationStatus.EXPIRED;
                emit DonationExpired(i, block.timestamp);
            }
        }
    }

    function getRaffleState() public view returns (DonorGleeRaffle.RaffleState state) {
        (bool callSuccess, bytes memory returnData) =
            i_raffleContract.staticcall(abi.encodeWithSignature("getRaffleStatus()"));
        if (!callSuccess) {
            revert DonorGleeFund__AccessToRaffleContractStateFailed();
        }

        state = abi.decode(returnData, (DonorGleeRaffle.RaffleState));

        return state;
    }

    function checkUpkeep(bytes memory /*checkData*/ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData*/ )
    {
        bool isTime = (block.timestamp - s_lastRaffleEntry >= i_raffleEntryInterval);
        bool hasPlayers = s_rafflePlayers.length > 0;
        bool hasPrizePool = s_prizePool > 0;
        bool isRaffleOpen = (getRaffleState() == DonorGleeRaffle.RaffleState.OPEN);

        upkeepNeeded = (isTime && hasPlayers && hasPrizePool && isRaffleOpen);
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /*performData*/ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert DonorGleeFund__NoUpkeepNeeded();
        }

        closeExpireDonations();

        uint256 raffleAmount = s_prizePool;
        address[] memory players = s_rafflePlayers;
        s_prizePool = 0;
        s_lastRaffleEntry = block.timestamp;
        s_rafflePlayers = new address[](0);

        (bool callSuccess,) = payable(i_raffleContract).call{value: raffleAmount}(
            abi.encodeWithSignature("enterRaffle(address[])", players)
        );
        if (!callSuccess) {
            revert DonorGleeFund__TransferFailed();
        }
    }

    function getTotalDonations() public view returns (uint256) {
        return s_donationCount;
    }

    function checkWalletWhiteListed(address wallet) public view returns (bool) {
        return s_whiteList[wallet];
    }

    function getDonationDetails(uint256 donationId) public view returns (Donation memory) {
        return s_donations[donationId];
    }

    function getPrizePoolForRaffleInCurrentSlot() public view returns (uint256) {
        return s_prizePool;
    }

    function getPlayersForRaffleInCurrentSlot() public view returns (uint256) {
        return s_rafflePlayers.length;
    }

    function getRaffleContract() public view returns (address) {
        return i_raffleContract;
    }

    function getLastRaffleEntryTime() public view returns (uint256) {
        return s_lastRaffleEntry;
    }

    function getTotalWhiteListedWallets() public view returns (uint256) {
        return s_cntWhiteListedWallets;
    }
}
