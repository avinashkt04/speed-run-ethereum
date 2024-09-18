// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

error Stacker__InvalidAmount();

contract Staker {
	// state variables
	mapping(address => uint256) public balances;
	uint256 public constant threshold = 1 ether;
	uint256 public deadline = block.timestamp + 72 hours;
	bool public openForWithdraw = false;
	uint256 public totalBalance = 0;
	ExampleExternalContract public exampleExternalContract;

	// Event
	event Stake(address, uint256);
	event Withdraw(address, uint256);

	// Modifier
	modifier notCompleted() {
		require(
			!exampleExternalContract.completed(),
			"Contract already completed"
		);
		_;
	}

	constructor(address exampleExternalContractAddress) {
		exampleExternalContract = ExampleExternalContract(
			exampleExternalContractAddress
		);
	}

	// Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
	// (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
	function stake() public payable {
		totalBalance += msg.value;
		balances[msg.sender] += msg.value;
		emit Stake(msg.sender, msg.value);
	}

	// After some `deadline` allow anyone to call an `execute()` function
	// If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
	function execute() public notCompleted {
		if (address(this).balance >= threshold && block.timestamp >= deadline) {
			exampleExternalContract.complete{ value: address(this).balance }();
		} else {
			openForWithdraw = true;
		}
	}

	// If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
	function withdraw() public payable notCompleted {
		require(
			threshold > address(this).balance,
			"Threshold met so you can't withdraw"
		);
		require(timeLeft() == 0, "Deadline not met yet");
		uint256 amount = balances[msg.sender];
		totalBalance -= amount;
		balances[msg.sender] = 0;
		(bool success, ) = msg.sender.call{ value: amount }("");
		emit Withdraw(msg.sender, amount);
	}

	// Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
	function timeLeft() public view returns (uint256) {
		if (block.timestamp >= deadline) return 0;
		return deadline - block.timestamp;
	}

	// Add the `receive()` special function that receives eth and calls stake()
	receive() external payable {
		stake();
	}
}
