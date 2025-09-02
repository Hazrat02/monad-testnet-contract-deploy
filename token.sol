// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CreatelizeToken is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10**18; // 1 Billion
    uint256 public constant DAILY_CLAIM_AMOUNT = 1 * 10**18; // 1 CMON daily

    mapping(address => uint256) public lastClaimed;

    constructor() ERC20("Createlize", "CMON") {
        _mint(msg.sender, TOTAL_SUPPLY); // Owner gets all tokens initially
    }

    // Users can claim 1 CMON daily
    function claimDaily() external {
        require(block.timestamp - lastClaimed[msg.sender] >= 24 hours, "Claim available once every 24h");
        lastClaimed[msg.sender] = block.timestamp;

        _mint(msg.sender, DAILY_CLAIM_AMOUNT);
    }
}
