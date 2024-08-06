// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DonorGleeRaffle} from "../src/DonorGleeRaffle.sol";
import {DonorGleeFund} from "../src/DonorGleeFund.sol";
import {CreateSubScription, FundSubscription, AddConsumer} from "./Interaction.s.sol";

contract DeployDonorGlee is Script {
    uint256 private constant MAXDONATION_INTERVAL = 60; //max donation active time can be 60 days
    uint256 private constant RAFFLE_ENTRY_INTERVAL = 1; //at the end of each day new comers will be added to the raffle contract for incentive
    uint256 private constant RAFFLE_INTERVAL = 2;

    function deployDonorGleeAsWhole() public returns (DonorGleeFund, DonorGleeRaffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinatorAdd,
            bytes32 keyHash,
            uint64 subId,
            uint32 callbackGasLimit,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetConfig();

        if (subId == 0) {
            CreateSubScription createSub = new CreateSubScription();
            subId = createSub.createSubscription(vrfCoordinatorAdd, deployerKey);
        }

        FundSubscription fundSubscription = new FundSubscription();
        subId = fundSubscription.fundSubscription(vrfCoordinatorAdd, subId, link, deployerKey);

        vm.startBroadcast(deployerKey);
        DonorGleeRaffle donorGleeRaffle =
            new DonorGleeRaffle(vrfCoordinatorAdd, RAFFLE_INTERVAL, keyHash, subId, callbackGasLimit);
        DonorGleeFund donorGleeFund =
            new DonorGleeFund(MAXDONATION_INTERVAL, RAFFLE_ENTRY_INTERVAL, address(donorGleeRaffle));
        donorGleeRaffle.transferOwnership(address(donorGleeFund));
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(vrfCoordinatorAdd, subId, deployerKey, address(donorGleeRaffle));

        return (donorGleeFund, donorGleeRaffle, helperConfig);
    }

    function run() external returns (DonorGleeFund, DonorGleeRaffle, HelperConfig) {
        return deployDonorGleeAsWhole();
    }
}
