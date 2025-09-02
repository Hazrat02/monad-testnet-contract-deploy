// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

contract SimpleSwap {
    address public owner;

    event Swapped(address indexed user, address tokenA, address tokenB, uint amountA, uint amountB);
    event Deposited(address indexed owner, address token, uint amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // Swap tokenA -> tokenB at fixed rate
    function swap(address tokenA, address tokenB, uint amountA, uint rate) external {
        require(amountA > 0, "Amount must be > 0");

        // Transfer tokenA from user to contract
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), "Transfer failed");

        uint amountB = (amountA * rate) / 1e18; // rate with 18 decimals
        require(IERC20(tokenB).balanceOf(address(this)) >= amountB, "Not enough tokenB");

        // Transfer tokenB to user
        require(IERC20(tokenB).transfer(msg.sender, amountB), "Transfer failed");

        emit Swapped(msg.sender, tokenA, tokenB, amountA, amountB);
    }

    // Owner deposits tokens to contract
    function deposit(address token, uint amount) external onlyOwner {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Deposit failed");
        emit Deposited(msg.sender, token, amount);
    }

    // Fallback & receive functions to accept native coin
    fallback() external payable {}
    receive() external payable {}
}
