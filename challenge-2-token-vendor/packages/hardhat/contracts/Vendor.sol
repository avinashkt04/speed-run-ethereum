pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";
import "hardhat/console.sol";

contract Vendor is Ownable {
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

  YourToken public yourToken;
  uint256 public constant tokensPerEth = 100;

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
  function buyTokens() public payable {
    uint256 amountOfETH = msg.value;
    uint256 amountOfTokens = tokensPerEth * amountOfETH;
    yourToken.transfer(msg.sender, amountOfTokens);
    emit BuyTokens(msg.sender, amountOfETH, amountOfTokens);
  }

  // ToDo: create a withdraw() function that lets the owner withdraw ETH
  function withdraw() public payable{
    require(msg.sender==owner(), "Not the owner");
    uint256 balance = address(this).balance;
    (bool success,) = msg.sender.call{value:balance}("");
    require(success, "Transfer failed.");
  }

  // ToDo: create a sellTokens(uint256 _amount) function:
  function sellTokens(uint256 _amount) public {
    yourToken.approve(address(this), _amount);
    uint256 etherAmount = _amount / tokensPerEth;
    require(address(this).balance >= etherAmount, "Vendor has insufficient ETH to sell tokens.");
    yourToken.transferFrom(msg.sender, address(this), _amount);
    payable(msg.sender).transfer(etherAmount);
    emit SellTokens(msg.sender, _amount, etherAmount);
  }
}
