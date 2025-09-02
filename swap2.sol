// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SimpleSwap {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // Swap function
    // fromToken: address of token user is sending
    // toToken: address of token user wants to receive
    // amount: amount of fromToken user is sending
    // convertRate: how many toToken units per 1 fromToken (e.g., 2 means 1 fromToken = 2 toToken)
    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 convertRate
    ) public {
        require(amount > 0, "Amount must be > 0");
        require(convertRate > 0, "Convert rate must be > 0");

        // Calculate how much toToken to send
        uint256 toAmount = amount * convertRate;

        // Check contract has enough toToken liquidity
        uint256 contractBalance = IERC20(toToken).balanceOf(address(this));
        require(contractBalance >= toAmount, "haven't liquidity");

        // Transfer fromToken from user to contract
        bool sentFrom = IERC20(fromToken).transferFrom(msg.sender, address(this), amount);
        require(sentFrom, "Transfer of fromToken failed");

        // Transfer toToken from contract to user
        bool sentTo = IERC20(toToken).transfer(msg.sender, toAmount);
        require(sentTo, "Transfer of toToken failed");
    }

    // Owner can withdraw any ERC20 token from contract
    function withdrawToken(address token, uint256 amount) public {
        require(msg.sender == owner, "Not the owner");
        IERC20(token).transfer(owner, amount);
    }

    // Get contract's token balance
    function getTokenBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}