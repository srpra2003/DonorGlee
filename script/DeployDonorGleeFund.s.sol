// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {DonorGleeFund} from "../src/DonorGleeFund.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFund is Script {
    uint256 private constant MAXDONATION_INTERVAL = 60; //max donation active time can be 60 days
    uint256 private constant RAFFLE_ENTRY_INTERVAL = 1; //at the end of each day new comers will be added to the raffle contract for incentive

    function deployDonorGleeFund(address raffleContract) public returns (DonorGleeFund, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (,,,,, uint256 deployerKey) = helperConfig.activeNetConfig();

        vm.startBroadcast(deployerKey);
        DonorGleeFund donorGleefund = new DonorGleeFund(MAXDONATION_INTERVAL, RAFFLE_ENTRY_INTERVAL, raffleContract);
        vm.stopBroadcast();

        return (donorGleefund, helperConfig);
    }

    function run(address raffleContract) external returns (DonorGleeFund, HelperConfig) {
        return deployDonorGleeFund(raffleContract);
    }
}
