// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {MockLinkToken} from "../test/mocks/MockLinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address vrfCoordinatorAdd;
        bytes32 keyHash;
        uint64 subId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    uint96 private constant BASE_FEE = 0.01 ether;
    uint96 private constant GASEPRICE_LINKS = 20000;
    NetworkConfig public activeNetConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetConfig = getSepoliaNetConfig();
        } else {
            activeNetConfig = getOrCreateAnvilNetConfig();
        }
    }

    function getSepoliaNetConfig() internal view returns (NetworkConfig memory) {
        NetworkConfig memory netConfig = NetworkConfig({
            vrfCoordinatorAdd: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, //100 gwei
            subId: 0,
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY")
        });

        return netConfig;
    }

    function getOrCreateAnvilNetConfig() internal returns (NetworkConfig memory) {
        if (activeNetConfig.vrfCoordinatorAdd != address(0)) {
            return activeNetConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(BASE_FEE, GASEPRICE_LINKS);
        MockLinkToken linkToken = new MockLinkToken();
        vm.stopBroadcast();

        NetworkConfig memory netConfig = NetworkConfig({
            vrfCoordinatorAdd: address(vrfCoordinator),
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, //100 gwei
            subId: 0,
            callbackGasLimit: 500000,
            link: address(linkToken),
            deployerKey: vm.envUint("ANVIL_PRIVATE_KEY")
        });

        return netConfig;
    }
}
