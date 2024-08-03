// SPDX-License-Identifier:MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DonorGleeRaffle} from "../src/DonorGleeRaffle.sol";

contract DeployRaffle is Script {

    uint256 private constant RAFFLE_INTERVAL = 2;

    function deployRaffleContract() public returns(DonorGleeRaffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinatorAdd,
            bytes32 keyHash,
            uint64 subId,
            uint32 callbackGasLimit,
            ,
            uint256 deployerKey
        ) = helperConfig.activeNetConfig();

        if(subId == 0){
            CreateSubScription createSub = new CreateSubScription();
            subId = createSub.createSubscription(vrfCoordinatorAdd,deployerKey);
        }

        FundSubscription fundSubscription = new FundSubscription();
        subId = fundSubscription.fundSubscription(vrfCoordinatorAdd,subId,link,deployerKey);

        vm.startBroadcast(deployerKey);
        DonorGleeRaffle donorGleeRaffle = new DonorGleeRaffle(vrfCoordinatorAdd,RAFFLE_INTERVAL,keyHash,subId,callbackGasLimit);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(vrfCoordinatorAdd,subId,deployerKey,address(donorGleeRaffle));

        return (donorGleeRaffle,helperConfig);
    }

    function deployRaffleContractWithOwnerContract(address ownerAdd) public returns(DonorGleeRaffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinatorAdd,
            bytes32 keyHash,
            uint64 subId,
            uint32 callbackGasLimit,
            ,
            uint256 deployerKey
        ) = helperConfig.activeNetConfig();

        vm.startBroadcast(deployerKey);
        DonorGleeRaffle donorGleeRaffle = new DonorGleeRaffle(vrfCoordinatorAdd,RAFFLE_INTERVAL,keyHash,subId,callbackGasLimit);
        donorGleeRaffle.transferOwnership(ownerAdd);
        vm.stopBroadcast();

        return (donorGleeRaffle,helperConfig);
    }


    function run() external returns(DonorGleeRaffle, HelperConfig){
        return deployRaffleContract();
    }
}
