// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    IERC20 token; // Token interface
    uint256 public totalLiquidity; // Total liquidity in the DEX
    mapping (address => uint256) public liquidity; // Liquidity of each user

    /* ========== EVENTS ========== */

    event EthToTokenSwap(address indexed swapper, uint256 tokenOutput, uint256 ethInput);
    event TokenToEthSwap(address indexed swapper, uint256 tokensInput, uint256 ethOutput);
    event LiquidityProvided(address indexed liquidityProvider, uint256 liquidityMinted, uint256 ethInput, uint256 tokensInput);
    event LiquidityRemoved(address indexed liquidityRemover, uint256 liquidityWithdrawn, uint256 tokensOutput, uint256 ethOutput);

    /* ========== CONSTRUCTOR ========== */

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr); // Assign token address
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: already has liquidity");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: Token transfer failed");
        return totalLiquidity;
    }

    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput * 997;
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = (xReserves * 1000) + xInputWithFee;
        return (numerator / denominator);
    }

    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp]; // Return the liquidity of the user
    }

    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "DEX: Cannot swap 0 ETH");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        tokenOutput = price(msg.value, ethReserve, tokenReserve);
        require(token.transfer(msg.sender, tokenOutput), "DEX: Token transfer failed");
        emit EthToTokenSwap(msg.sender, tokenOutput, msg.value);
        return tokenOutput;
    }

    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "DEX: Cannot swap 0 token");
        uint256 tokenReserve = token.balanceOf(address(this));
        ethOutput = price(tokenInput, tokenReserve, address(this).balance);
        require(token.transferFrom(msg.sender, address(this), tokenInput), "DEX: Token transfer failed");
        (bool sent, ) = msg.sender.call{ value: ethOutput }("");
        require(sent, "DEX: ETH transfer failed");
        emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
        return ethOutput;
    }

    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "DEX: Must send ETH to deposit");
        uint256 ethReserve = address(this).balance - msg.value;
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokenDeposit = (msg.value * tokenReserve / ethReserve) + 1;
        uint256 liquidityMinted = msg.value * totalLiquidity / ethReserve;
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;
        require(token.transferFrom(msg.sender, address(this), tokenDeposit), "DEX: Token transfer failed");
        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenDeposit);
        return tokenDeposit;
    }

    function withdraw(uint256 amount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        require(liquidity[msg.sender] >= amount, "DEX: Insufficient liquidity");
        uint256 ethReserve = address(this).balance;
        uint256 tokenReserve = token.balanceOf(address(this));
        ethAmount = amount * ethReserve / totalLiquidity;
        tokenAmount = amount * tokenReserve / totalLiquidity;
        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;
        (bool sent, ) = payable(msg.sender).call{ value: ethAmount }("");
        require(sent, "DEX: ETH transfer failed");
        require(token.transfer(msg.sender, tokenAmount), "DEX: Token transfer failed");
        emit LiquidityRemoved(msg.sender, amount, tokenAmount, ethAmount);
        return (ethAmount, tokenAmount);
    }
}
