//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe s_fundme;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.003 ether;
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 constant GAS_PRICE = 1 gwei;

    function setUp() external {
        // s_fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        s_fundme = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollerIsFive() public view {
        console.log("MINIMUM_USD: ", s_fundme.MINIMUM_USD());
        assertEq(s_fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log("Deployer:", s_fundme.getOwner());
        console.log("Msg Sender:", msg.sender);
        console.log("Conract Address:", address(this));
        assertEq(s_fundme.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        if (block.chainid == 11155111) {
            uint256 version = s_fundme.getVersion();
            console.log("Price Feed Version:", version);
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = s_fundme.getVersion();
            console.log("Price Feed Version:", version);
            assertEq(version, 6);
        }
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //hey, the next line, should revert!

        s_fundme.fund(); //send 0 value(ETH)
        // s_fundme.fund{value: 10e18}(); //send 10 value(ETH)
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next tx will be sent by USER
        s_fundme.fund{value: SEND_VALUE}();
        uint256 amountFunded = s_fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        s_fundme.fund{value: SEND_VALUE}();

        address funder = s_fundme.getFunders(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        s_fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert(); //hey, the next line, should revert!
        s_fundme.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = s_fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(s_fundme).balance;

        // Act
        vm.prank(s_fundme.getOwner());
        s_fundme.withdraw();

        // Assert
        uint256 endingOwnerBalance = s_fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(s_fundme).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithDrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i <= numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            s_fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(s_fundme).balance;
        uint256 startingOwnerBalance = s_fundme.getOwner().balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE); // Set the gas price for the transaction in the test
        vm.startPrank(s_fundme.getOwner()); // Start the prank (simulated transaction)
        s_fundme.withdraw(); // Execute the transaction
        vm.stopPrank(); // Stop the prank

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // Calculate the gas used with the actual gas price
        console.log("GAS USED: ", gasUsed);

        // Assert
        uint256 endingFundMeBalance = address(s_fundme).balance;
        uint256 endingOwnerBalance = s_fundme.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );

        /* assertEq(address(s_fundme).balance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            s_fundme.getOwner().balance
        ); */
    }

    function testWithDrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i <= numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            s_fundme.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(s_fundme).balance;
        uint256 startingOwnerBalance = s_fundme.getOwner().balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE); // Set the gas price for the transaction in the test
        vm.startPrank(s_fundme.getOwner()); // Start the prank (simulated transaction)
        s_fundme.cheaperWithdraw(); // Execute the transaction
        vm.stopPrank(); // Stop the prank

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // Calculate the gas used with the actual gas price
        console.log("GAS USED: ", gasUsed);

        // Assert
        uint256 endingFundMeBalance = address(s_fundme).balance;
        uint256 endingOwnerBalance = s_fundme.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
}
