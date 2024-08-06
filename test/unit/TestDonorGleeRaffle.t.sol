//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployDonorGleeRaffel.s.sol";
import {DonorGleeRaffle} from "../../src/DonorGleeRaffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Vm} from "forge-std/Vm.sol";

contract TestDonorGleeRaffle is Test {
    DeployRaffle private deployDonorGleeRaffle;
    DonorGleeRaffle private donorGleeRaffle;
    HelperConfig private helperConfig;
    address private USER = makeAddr("mainUser");
    uint256 private constant INITIAL_BALANCE = 100 ether;
    uint256 private constant RAFFLE_INTERVAL = 2;

    address private vrfCoordinatorAdd;
    bytes32 private keyHash;
    uint64 private subId;
    uint32 private callbackGasLimit;
    address private link;
    uint256 private deployerKey;

    event RaffleEntered(address[] players, uint256 raffleEnteredAmount);


    function setUp() public {
        deployDonorGleeRaffle = new DeployRaffle();
        (donorGleeRaffle, helperConfig) = deployDonorGleeRaffle.run();

        (vrfCoordinatorAdd, keyHash, subId, callbackGasLimit, link, deployerKey) = helperConfig.activeNetConfig();
        (,,, subId,) = donorGleeRaffle.getConstructorArgs();

        vm.deal(USER, INITIAL_BALANCE);
    }

    function testOwnerIsNotDeployScriptOrThisTestContrct() public {
        vm.prank(USER);
        address donorRaffleOwner = donorGleeRaffle.getOwner();
        address deployRaffleAdd = address(donorGleeRaffle);

        console.log(donorRaffleOwner);
        console.log(deployRaffleAdd);

        assert(deployRaffleAdd != donorRaffleOwner);
        assert(donorRaffleOwner == vm.addr(deployerKey)); //Actual owner of raffle contract
    }

    function testContractInitiizeInOpenState() public {
        vm.prank(USER);
        DonorGleeRaffle dnRaffleTemp =
            new DonorGleeRaffle(vrfCoordinatorAdd, RAFFLE_INTERVAL, keyHash, subId, callbackGasLimit);

        assert(dnRaffleTemp.getRaffleStatus() == DonorGleeRaffle.RaffleState.OPEN);
    }

    function testSubIdIsNotZeroAfterDeployment() public view {
        console.log(subId);
        assert(subId != 0);
    }

    function testRevertsWhenInvalidPersonTriesToEnterRaffle() public {
        address[] memory tempPlayer = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            tempPlayer[i] = address(uint160(i));
        }

        vm.prank(USER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        donorGleeRaffle.enterRaffle{value: 2 ether}(tempPlayer);
    }

    function testOwnerCanEnterNewPlayersToRaffle() public {
        address[] memory tempPlayers = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            tempPlayers[i] = address(uint160(i+1));
        }

        address mainOwner = donorGleeRaffle.getOwner();

        vm.prank(mainOwner);
        vm.deal(mainOwner,100 ether);
        vm.expectEmit(address(donorGleeRaffle));
        emit RaffleEntered(tempPlayers,2 ether);
        donorGleeRaffle.enterRaffle{value: 2 ether}(tempPlayers);
    }

    function testPlayersCanNotInfluenceRaffleByDuplicacy() public RaffleEnteredOnce{
        //Players From address 0x1 to 0xA are added to raffle by RaffleEnteredOnce

        address[] memory tempPlayers = new address[](5);
        for(uint256 i = 8; i < 13; i++){               //new teamPlayers are 0x9 to 0xD 
            tempPlayers[i-8] = address(uint160(i+1));
        }

        address mainOwner = donorGleeRaffle.getOwner();
        uint256 startPlayersCount = donorGleeRaffle.getTotalPlayersInCurrentRaffle();

        vm.prank(mainOwner);
        vm.deal(mainOwner,100 ether);
        donorGleeRaffle.enterRaffle{value: 5 ether}(tempPlayers);

        uint256 endPlatyersCount = donorGleeRaffle.getTotalPlayersInCurrentRaffle();

        console.log(startPlayersCount);
        console.log(endPlatyersCount);

        vm.expectRevert();
        assert(startPlayersCount+5 == endPlatyersCount);
    }

    function testOwnerCannotEnterRaffleWhenItIsInCalculatingState() public RaffleEnteredOnce{

        vm.warp(block.timestamp+(RAFFLE_INTERVAL* (1 days))+10);
        vm.roll(block.number+1);

        vm.prank(USER);  //let set USER as he is the chainlink keeper and avoking performUPkeep method
        vm.recordLogs();
        donorGleeRaffle.performUpkeep("0x0");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        console.log(uint256(entries[0].topics[1]));
        console.log(uint256(donorGleeRaffle.getRaffleStatus()));
        
        address mainOwner = donorGleeRaffle.getOwner();
        vm.prank(mainOwner);
        vm.deal(mainOwner,100 ether);
        vm.expectRevert(DonorGleeRaffle.DonorGleeRaffle__RaffleIsCALCULATING.selector);
        donorGleeRaffle.enterRaffle{value: 3 ether}(new address[](10));
    }



    modifier RaffleEnteredOnce {
        address[] memory tempPlayers = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            tempPlayers[i] = address(uint160(i+1));
        }

        address mainOwner = donorGleeRaffle.getOwner();

        vm.prank(mainOwner);
        vm.deal(mainOwner,100 ether);

        donorGleeRaffle.enterRaffle{value: 2 ether}(tempPlayers);       
        _;
    }
}
