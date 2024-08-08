// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console, Vm} from "forge-std/Test.sol";
import {DeployFund} from "../../script/DeployDonorGleeFund.s.sol";
import {DeployRaffle} from "../../script/DeployDonorGleeRaffel.s.sol";
import {DonorGleeFund} from "../../src/DonorGleeFund.sol";
import {DonorGleeRaffle} from "../../src/DonorGleeRaffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract TestDonorGleeFund is Test {
    DeployFund private deployDonorGleeFund;
    DonorGleeFund private donorGleeFund;
    DeployRaffle private deployDonorGleeRaffle;
    DonorGleeRaffle private donorGleeRaffle;
    HelperConfig private helperConfig;
    address private USER = makeAddr("user");
    uint256 private INITIAL_BALANCE = 100 ether;
    uint256 private constant MAXDONATION_INTERVAL = 60; //max donation active time can be 60 days
    uint256 private constant RAFFLE_ENTRY_INTERVAL = 1; //at the end of each day new comers will be added to the raffle contract for incentive
    uint256 private constant RAFFLE_INTERVAL = 2;

    address private vrfCoordinatorAdd;
    bytes32 private keyHash;
    uint64 private subId;
    uint32 private callbackGasLimit;
    address private link;
    uint256 private deployerKey;

    event DonationCreated(address indexed creator, address indexed wallet, uint256 donationId);
    event DonationExpired(uint256 indexed donationId, uint256 timeStamp);
    event DonationWithdrawn(address indexed creator, uint256 donationId, uint256 timeStamp, uint256 withdrawAmount);

    function setUp() public {
        deployDonorGleeFund = new DeployFund();
        deployDonorGleeRaffle = new DeployRaffle();

        (donorGleeRaffle, helperConfig) = deployDonorGleeRaffle.deployRaffleContract();
        (donorGleeFund, helperConfig) = deployDonorGleeFund.deployDonorGleeFund(address(donorGleeRaffle));

        (vrfCoordinatorAdd, keyHash, subId, callbackGasLimit, link, deployerKey) = helperConfig.activeNetConfig();

        vm.deal(USER, INITIAL_BALANCE);
    }

    function testFundContractIsOwnerOfRaffleContract() public view {
        assertEq(address(donorGleeFund), donorGleeRaffle.getOwner());
    }

    function testAnyoneCanCreateDonation() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER);
        vm.expectEmit(true, true, false, true, address(donorGleeFund));
        emit DonationCreated(USER, _donationWalletAdd, 0);
        vm.recordLogs();
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        Vm.Log[] memory entries = vm.getRecordedLogs();

        DonorGleeFund.Donation memory donation = donorGleeFund.getDonationDetails(donationId);

        assertEq(address(uint160(uint256(entries[0].topics[1]))), USER);
        assertEq(address(uint160(uint256(entries[0].topics[2]))), _donationWalletAdd);
        assertEq(1, donorGleeFund.getTotalDonations());
        assertEq(donation.name, _donationName);
        assertEq(donation.description, _donationDescription);
        assertEq(donation.creator, USER);
        assertEq(donation.walletAdd, _donationWalletAdd);
        assertEq(donation.goal, _donationGoal);
    }

    function testDonationGetsPromotedIfWalletIsWhiteListedPriorToDonationCreation() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        address fundContractOwner = vm.addr(deployerKey);
        vm.deal(fundContractOwner, INITIAL_BALANCE);

        vm.startPrank(fundContractOwner);
        donorGleeFund.addWalletToWhiteList(_donationWalletAdd);
        vm.stopPrank();

        vm.prank(USER);
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );
        DonorGleeFund.Donation memory donation = donorGleeFund.getDonationDetails(donationId);

        assertEq(donation.isPromoted, true);
        assertEq(donorGleeFund.checkWalletWhiteListed(_donationWalletAdd), true);
    }

    function testDonationGetsPromotedIfWalletGetsWhiteListedAfterCreationOfDonation() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER);
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        address fundContractOwner = vm.addr(deployerKey);
        vm.deal(fundContractOwner, INITIAL_BALANCE);

        vm.prank(fundContractOwner);
        donorGleeFund.addWalletToWhiteList(_donationWalletAdd);
        DonorGleeFund.Donation memory donation = donorGleeFund.getDonationDetails(donationId);
        console.log(donation.name);

        assertEq(donation.isPromoted, true);
    }

    function testDonationToInvalidDontaionReverts() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER);
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        address testFunder = makeAddr("testAddress");
        vm.deal(testFunder, INITIAL_BALANCE);

        vm.prank(testFunder);
        vm.expectRevert(DonorGleeFund.DonorGleeFund__InvalidAmount.selector);
        donorGleeFund.fundDonation{value: 0 ether}(donationId); //Invalid amount funding error

        vm.expectRevert(DonorGleeFund.DonorGleeFund__InvalidDonation.selector);
        donorGleeFund.fundDonation{value: 2 ether}(donationId + 100); //Invalid donationId

        vm.warp(block.timestamp + (_donationActiveTime * (1 days)) + 1);
        vm.roll(block.number + 1);

        vm.expectEmit(true, false, false, true, address(donorGleeFund));
        emit DonationExpired(donationId, block.timestamp);
        donorGleeFund.closeExpireDonations();

        vm.expectRevert(DonorGleeFund.DonorGleeFund__DonationSessionIsExpired.selector);
        donorGleeFund.fundDonation{value: 2 ether}(donationId); //Expired Donation Funding
    }

    function testOnly98PercentValueOfSentValueIsFundedToDonation() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER);
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        address funder = makeAddr("TestFunder");
        uint256 actualFundedValue = 2 ether;
        vm.deal(funder, INITIAL_BALANCE);
        vm.prank(funder);
        donorGleeFund.fundDonation{value: actualFundedValue}(donationId);
        DonorGleeFund.Donation memory donation = donorGleeFund.getDonationDetails(donationId);
        uint256 fundedBalanceToDonation = donation.funds;
        uint256 fundedBalanceToPrizePool = donorGleeFund.getPrizePoolForRaffleInCurrentSlot();

        console.log(actualFundedValue);
        console.log(fundedBalanceToDonation);
        console.log(fundedBalanceToPrizePool);

        assertEq((actualFundedValue * 98) / 100, fundedBalanceToDonation);
        assertEq(actualFundedValue, fundedBalanceToDonation + fundedBalanceToPrizePool);
    }

    function testDonationCreatorCanWithDrawTheFundedMoney() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER); //Donation Creator is USER
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        for (uint256 funderPos = 0; funderPos < 10; funderPos++) {
            // 10 funders are funding to the donation
            address funderAdd = address(uint160(funderPos + 1));
            uint256 fixedValueToFund = 1 ether;
            hoax(funderAdd, INITIAL_BALANCE);
            donorGleeFund.fundDonation{value: fixedValueToFund + funderPos}(donationId);
        }

        DonorGleeFund.Donation memory donation = donorGleeFund.getDonationDetails(donationId);
        uint256 startDonationBalance = donation.funds;

        vm.prank(USER);
        vm.expectEmit(true, false, false, true, address(donorGleeFund));
        emit DonationWithdrawn(USER, donationId, block.timestamp, startDonationBalance);
        donorGleeFund.redeemDonation(donationId);

        donation = donorGleeFund.getDonationDetails(donationId);
        uint256 endDonationBalance = donation.funds;
        uint256 endWalletBalance = _donationWalletAdd.balance;

        assertEq(endDonationBalance, 0);
        assertEq(endWalletBalance, startDonationBalance);
    }

    function testRevertsWhenIllegealPersonTriesToWithdrawDonationFunds() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER); //Donation Creator is USER
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        for (uint256 funderPos = 0; funderPos < 10; funderPos++) {
            // 10 funders are funding to the donation
            address funderAdd = address(uint160(funderPos + 1));
            uint256 fixedValueToFund = 1 ether;
            hoax(funderAdd, INITIAL_BALANCE);
            donorGleeFund.fundDonation{value: fixedValueToFund + funderPos}(donationId);
        }

        address illegalUser = makeAddr("illegalUser");
        vm.deal(illegalUser, INITIAL_BALANCE);

        vm.prank(illegalUser);
        vm.expectRevert(
            abi.encodeWithSelector(DonorGleeFund.DonorGleeFund__IllegealAccessToDonation.selector, illegalUser)
        );
        donorGleeFund.redeemDonation(donationId);
    }

    function testDonationCreationRevertsWhenInvalidActiveTimeIsPassed() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        // uint256 _donationActiveTime = 30; //In days

        vm.prank(USER); //Donation Creator is USER
        vm.expectRevert(DonorGleeFund.DonorGleeFund__InvalidActiveTime.selector);
        donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, MAXDONATION_INTERVAL + 1
        );
    }

    function testCloseExpireDonationClosesExpireDonationPerfectly() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER); //Donation Creator is USER
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        vm.warp(block.timestamp + (_donationActiveTime * (1 days)) + 1);
        vm.roll(block.number + 1);

        address testPerson = makeAddr("TestPerson");
        vm.deal(testPerson, INITIAL_BALANCE);
        vm.prank(testPerson);
        vm.expectEmit(true, false, false, true, address(donorGleeFund));
        emit DonationExpired(donationId, block.timestamp);
        donorGleeFund.closeExpireDonations();
    }

    function testgetRaffleTestFetchesTheRaffleStateCorrectly() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER); //Donation Creator is USER
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        for (uint256 funderPos = 0; funderPos < 10; funderPos++) {
            // 10 funders are funding to the donation
            address funderAdd = address(uint160(funderPos + 1));
            uint256 fixedValueToFund = 1 ether;
            hoax(funderAdd, INITIAL_BALANCE);
            donorGleeFund.fundDonation{value: fixedValueToFund + funderPos}(donationId);
        }
        assertEq(donorGleeFund.getPlayersForRaffleInCurrentSlot(), 10);

        console.log(address(donorGleeRaffle));
        console.log(donorGleeFund.getRaffleContract());

        DonorGleeRaffle.RaffleState state = donorGleeFund.getRaffleState(); //when raffle is open
        console.log(uint256(state));
        assertEq(uint256(state), 0);

        vm.warp(block.timestamp + (RAFFLE_ENTRY_INTERVAL * 1 days) + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = donorGleeFund.checkUpkeep("0x0");
        console.log(upkeepNeeded);

        vm.prank(USER);
        donorGleeFund.performUpkeep("0x0");

        vm.warp(block.timestamp + (RAFFLE_INTERVAL * (1 days)) + 1);
        vm.roll(block.number + 1);
        (upkeepNeeded,) = donorGleeRaffle.checkUpkeep("0x0");
        console.log(upkeepNeeded);
        donorGleeRaffle.performUpkeep("0x0");

        console.log(uint256(donorGleeRaffle.getRaffleStatus()));

        state = donorGleeFund.getRaffleState(); //when raffle is in calculating mode
        console.log(uint256(state));
    }

    function testPerformUpkeepRevertsWhenTimeHasNotPassedYet() public {
        console.log(block.timestamp);
        console.log(donorGleeFund.getLastRaffleEntryTime());

        vm.expectRevert(DonorGleeFund.DonorGleeFund__NoUpkeepNeeded.selector);
        donorGleeFund.performUpkeep("0x0");
    }

    function testPerformUpkeepRevertsWhenThereAreNoPlayersInSystem() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER); //Donation Creator is USER
        donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        vm.warp(block.timestamp + (RAFFLE_ENTRY_INTERVAL * (1 days)) + 1);
        vm.roll(block.number + 1);

        vm.expectRevert(DonorGleeFund.DonorGleeFund__NoUpkeepNeeded.selector);
        donorGleeFund.performUpkeep("0x0");
    }

    function testPerformUpkeepRevertsWhenRaffleContractIsInCalculatingState() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER); //Donation Creator is USER
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        vm.warp(block.timestamp + (RAFFLE_ENTRY_INTERVAL * (1 days)) + 1); //Time has passed
        vm.roll(block.number + 1);

        for (uint256 funderPos = 0; funderPos < 10; funderPos++) {
            // 10 funders are funding to the donation
            address funderAdd = address(uint160(funderPos + 1));
            uint256 fixedValueToFund = 1 ether;
            hoax(funderAdd, INITIAL_BALANCE);
            donorGleeFund.fundDonation{value: fixedValueToFund + funderPos}(donationId);
        }

        vm.prank(USER);
        donorGleeFund.performUpkeep("0x0");

        vm.warp(block.timestamp + (RAFFLE_INTERVAL * (1 days)) + 1);
        vm.roll(block.number + 1);
        donorGleeRaffle.performUpkeep("0x0");

        for (uint256 funderPos = 0; funderPos < 10; funderPos++) {
            // 10 funders are funding to the donation
            address funderAdd = address(uint160(funderPos + 12));
            uint256 fixedValueToFund = 1 ether;
            hoax(funderAdd, INITIAL_BALANCE);
            donorGleeFund.fundDonation{value: fixedValueToFund + funderPos}(donationId);
        }

        vm.expectRevert(DonorGleeFund.DonorGleeFund__NoUpkeepNeeded.selector);
        donorGleeFund.performUpkeep("0x0");
    }

    function testPerformUpkeepResetsTheSlotsDataForRaffleContract() public {
        string memory _donationName = "testDonation";
        string memory _donationDescription = "This is just a test donation";
        address _donationWalletAdd = makeAddr("wallletAdd");
        uint256 _donationGoal = 20 ether;
        uint256 _donationActiveTime = 30; //In days

        vm.prank(USER); //Donation Creator is USER
        uint256 donationId = donorGleeFund.createDonation(
            _donationName, _donationDescription, _donationWalletAdd, _donationGoal, _donationActiveTime
        );

        vm.warp(block.timestamp + (RAFFLE_ENTRY_INTERVAL * (1 days)) + 1); //Time has passed
        vm.roll(block.number + 1);

        for (uint256 funderPos = 0; funderPos < 10; funderPos++) {
            // 10 funders are funding to the donation
            address funderAdd = address(uint160(funderPos + 1));
            uint256 fixedValueToFund = 1 ether;
            hoax(funderAdd, INITIAL_BALANCE);
            donorGleeFund.fundDonation{value: fixedValueToFund + funderPos}(donationId);
        }

        uint256 startingFundContractBalance = address(donorGleeFund).balance;
        uint256 startingPrizePool = donorGleeFund.getPrizePoolForRaffleInCurrentSlot();

        vm.prank(USER);
        donorGleeFund.performUpkeep("0x0");
        uint256 endingFundContractBalance = address(donorGleeFund).balance;

        assertEq(block.timestamp, donorGleeFund.getLastRaffleEntryTime());
        assertEq(0, donorGleeFund.getPrizePoolForRaffleInCurrentSlot());
        assertEq(0, donorGleeFund.getPlayersForRaffleInCurrentSlot());
        assert(startingFundContractBalance - startingPrizePool <= endingFundContractBalance);
    }
}
