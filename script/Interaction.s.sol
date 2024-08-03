// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {LinkTokenInterface} from "@chainlink/v0.8/shared/interfaces/LinkTokenInterface.sol";


contract CreateSubScription is Script{

    function createSubscription(address vrfCoordinatorAdd, uint256 deployerKey) public returns(uint64){
        
        vm.startBroadcast(deployerKey);
        uint64 subId = VRFCoordinatorV2Mock(vrfCoordinatorAdd).createSubscription();
        vm.stopBroadcast();

        return subId;
    }

    function createSubscriptionWithoutConfig() public returns(uint64){
        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinatorAdd,
            ,
            ,
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.activeNetConfig();

        return createSubscription(vrfCoordinatorAdd,deployerKey);
    }
    
    function run() external returns(uint64){
        return createSubscriptionWithoutConfig();
    }
}



contract FundSubscription is Script {

    uint96 private constant AMOUNT_TO_FUND = 20 ether;

    function fundSubscription(address vrfCoordinatorAdd, uint64 subId, address link, uint256 deployerKey) public returns(uint64){

        if(subId == 0){
            CreateSubScription createSub = new CreateSubScription();
            subId = createSub.createSubscription(vrfCoordinatorAdd,deployerKey);
        }

        vm.startBroadcast(deployerKey);
        if(block.chainid == 315337){
            VRFCoordinatorV2Mock(vrfCoordinatorAdd).fundSubscription(subId,AMOUNT_TO_FUND);
        }
        else{
            LinkTokenInterface(link).transferAndCall(vrfCoordinatorAdd,AMOUNT_TO_FUND,abi.encode(subId));
        }
        vm.stopBroadcast();

        return subId;
    }

    function fundSubscriptionWithoutConfig() public returns(uint256){

        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinatorAdd,
            ,
            uint64 subId,
            ,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetConfig();

        return fundSubscription(vrfCoordinatorAdd,subId,link,deployerKey);
        
    }

    function run() external returns(uint256){
        return fundSubscriptionWithoutConfig();
    }
}



contract AddConsumer is Script {

    function addConsumer(address vrfCoordinatorAdd, uint64 subId, uint256 deployerKey, address consumer) public returns(uint64){

        if(subId == 0){
            CreateSubScription createSub = new CreateSubScription();
            subId = createSub.createSubscription(vrfCoordinatorAdd,deployerKey);
        }
        
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinatorAdd).addConsumer(subId,consumer);
        vm.stopBroadcast();

        return subId;
    }

    function addConsumerWithoutConfig(address consumer) public returns(uint64){

        HelperConfig helperConfig = new HelperConfig();
        (
            address vrfCoordinatorAdd,
            ,
            uint64 subId,
            ,
            ,
            uint256 deployerKey
        ) = helperConfig.activeNetConfig();

        return addConsumer(vrfCoordinatorAdd,subId,deployerKey,consumer);

    }

    function run() external returns(uint64){
        address lastDeployed = DevOpsTools.get_most_recent_deployment("DonorGleeRaffle",block.chainid);
        return addConsumerWithoutConfig(lastDeployed);
    }

}