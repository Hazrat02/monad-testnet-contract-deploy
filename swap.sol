// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

contract SimpleSwap {
    address public owner;
    uint256 public constant swapFee = 0.1 ether; // fixed fee

    event Swapped(address indexed user, address tokenA, address tokenB, uint amountA, uint amountB);
    event Deposited(address indexed owner, address token, uint amount);
    event Withdrawn(address indexed owner, address token, uint amount);
    event FeesWithdrawn(address indexed owner, uint amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // Swap tokenA -> tokenB at fixed rate
    function swap(address tokenA, address tokenB, uint amountA, uint rate) external payable {
        require(msg.value >= swapFee, "Insufficient fee sent");
        require(amountA > 0, "Amount must be > 0");

        // Transfer tokenA from user to contract (user must approve first)
        bool successA = IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        require(successA, "TokenA transfer failed");

        // Calculate how much tokenB to send
        uint amountB = (amountA * rate) / 1e18; // rate scaled to 18 decimals
        require(IERC20(tokenB).balanceOf(address(this)) >= amountB, "Not enough tokenB in pool");

        // Send tokenB to user
        bool successB = IERC20(tokenB).transfer(msg.sender, amountB);
        require(successB, "TokenB transfer failed");

        emit Swapped(msg.sender, tokenA, tokenB, amountA, amountB);
    }

    // Owner deposits tokenB into contract
    function deposit(address token, uint amount) external onlyOwner {
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Deposit failed");
        emit Deposited(msg.sender, token, amount);
    }

    // Owner withdraws tokens
    function withdraw(address token, uint amount) external onlyOwner {
        bool success = IERC20(token).transfer(msg.sender, amount);
        require(success, "Withdraw failed");
        emit Withdrawn(msg.sender, token, amount);
    }

    // Owner withdraws collected ETH fees
    function withdrawFees() external onlyOwner {
        uint bal = address(this).balance;
        require(bal > 0, "No fees to withdraw");
        payable(owner).transfer(bal);
        emit FeesWithdrawn(owner, bal);
    }

    // Allow contract to receive ETH
    fallback() external payable {}
    receive() external payable {}
}
