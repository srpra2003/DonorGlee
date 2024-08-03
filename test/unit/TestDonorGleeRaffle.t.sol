//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployDonorGleeRaffel.s.sol";
import {DonorGleeRaffle} from "../../src/DonorGleeRaffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract TestDonorGleeRaffle is Test {

    DeployRaffle deployDonorGleeRaffle;
    DonorGleeRaffle donorGleeRaffle;
    HelperConfig helperConfig;

    function setUp() public {

        deployDonorGleeRaffle = new DeployRaffle();
        (donorGleeRaffle,helperConfig) = deployDonorGleeRaffle.run();

    }
}