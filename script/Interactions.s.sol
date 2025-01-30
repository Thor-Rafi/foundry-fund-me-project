//SPDX-License-Identifier: MIT

// Fund Script
// Withdraw Script

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.003 ether;

    function fundFundMe(address mostRecentlyDeployedContractAddress) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployedContractAddress)).fund{
            value: SEND_VALUE
        }();
        vm.stopBroadcast();
        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployedContractAddress = DevOpsTools
            .get_most_recent_deployment("FundMe", block.chainid);
        vm.startBroadcast();
        fundFundMe(mostRecentlyDeployedContractAddress);
        vm.stopBroadcast();
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(
        address mostRecentlyDeployedContractAddress
    ) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployedContractAddress)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployedContractAddress = DevOpsTools
            .get_most_recent_deployment("FundMe", block.chainid);
        vm.startBroadcast();
        withdrawFundMe(mostRecentlyDeployedContractAddress);
        vm.stopBroadcast();
    }
}
