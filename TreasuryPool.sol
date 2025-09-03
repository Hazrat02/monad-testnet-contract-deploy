// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Gmonad {
    string public greeting;
    address public owner;
    uint256 public callFee = 0.001 ether;

    // Track per-token balances inside contract
    mapping(address => uint256) public totalTokenBalance;


    event Deposited(address indexed from, address token, uint256 amount);
    event Swapped(address indexed user, address tokenA, address tokenB, uint256 amountA, uint256 amountB);


    // Track user balances: user => token => amount
    mapping(address => mapping(address => uint256)) public userBalances;

    // Track all tokens contract has seen (for portfolio listing)
    address[] public trackedTokens;

    constructor(string memory _greeting) payable {
        greeting = _greeting;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    // ---------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------
    function _toWei(address _token, uint256 _amount) internal view returns (uint256) {
        uint8 decimals = IERC20Metadata(_token).decimals();
        return _amount * (10 ** uint256(decimals));
    }

    // ---------------------------------------------------------
    // Greeting
    // ---------------------------------------------------------
    function setGreeting(string calldata _greeting) external payable {
        require(msg.value >= callFee, "Insufficient fee sent");
        greeting = _greeting;
    }

    // ---------------------------------------------------------
    // Withdraw
    // ---------------------------------------------------------
    function withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawToken(address _token) external onlyOwner {
        IERC20 erc20 = IERC20(_token);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance > 0, "No token balance");
        erc20.transfer(owner, balance);
    }

    function withdrawWmon() external onlyOwner {
        address wmon = 0x760AfE86e5de5fa0Ee542fc7B7B713e1c5425701;
        IERC20 erc20 = IERC20(wmon);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance > 0, "No token balance");
        erc20.transfer(owner, balance);
    }

    // ---------------------------------------------------------
    // Deposit
    // ---------------------------------------------------------
    function deposit(address _token, uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");

        IERC20 token = IERC20(_token);
        uint256 weiAmount = _toWei(_token, _amount);

        uint256 allowed = token.allowance(msg.sender, address(this));
        require(allowed >= weiAmount, "Not enough allowance");

        bool success = token.transferFrom(msg.sender, address(this), weiAmount);
        require(success, "Transfer failed");

        totalTokenBalance[_token] += weiAmount;
        emit Deposited(msg.sender, _token, weiAmount);
    }

    function depositWmon(uint256 _amount) external {
        address wmon = 0x760AfE86e5de5fa0Ee542fc7B7B713e1c5425701;
        IERC20 token = IERC20(wmon);

        uint256 weiAmount = _toWei(wmon, _amount);
        uint256 allowed = token.allowance(msg.sender, address(this));
        require(allowed >= weiAmount, "Not enough allowance");

        bool success = token.transferFrom(msg.sender, address(this), weiAmount);
        require(success, "Transfer failed");

        totalTokenBalance[wmon] += weiAmount;
        emit Deposited(msg.sender, wmon, weiAmount);
    }

    function depositOwner(address _token, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 weiAmount = _toWei(_token, _amount);

        uint256 allowed = token.allowance(msg.sender, address(this));
        require(allowed >= weiAmount, "Not enough allowance");

        bool success = token.transferFrom(msg.sender, address(this), weiAmount);
        require(success, "Transfer failed");

        totalTokenBalance[_token] += weiAmount;
        emit Deposited(msg.sender, _token, weiAmount);
    }

    // ---------------------------------------------------------
    // Swap
    // ---------------------------------------------------------
    function swap(address tokenA, address tokenB, uint256 amountA, uint256 rate) external payable {
        require(msg.value >= callFee, "Insufficient fee sent");
        require(amountA > 0, "Amount must be > 0");

        IERC20 tA = IERC20(tokenA);
        IERC20 tB = IERC20(tokenB);

        uint256 weiAmountA = _toWei(tokenA, amountA);

        // Check allowance for tokenA
        uint256 allowed = tA.allowance(msg.sender, address(this));
        require(allowed >= weiAmountA, "Not enough allowance");

        // Transfer tokenA from user
        bool successA = tA.transferFrom(msg.sender, address(this), weiAmountA);
        require(successA, "TokenA transfer failed");

        // Calculate amountB using rate (scaled to 1e18)
        uint256 weiAmountB = (weiAmountA * rate) / 1e18;
        require(tB.balanceOf(address(this)) >= weiAmountB, "Not enough tokenB in pool");

        // Transfer tokenB to user
        bool successB = tB.transfer(msg.sender, weiAmountB);
        require(successB, "TokenB transfer failed");

        totalTokenBalance[tokenA] += weiAmountA;
        totalTokenBalance[tokenB] -= weiAmountB;

        emit Swapped(msg.sender, tokenA, tokenB, weiAmountA, weiAmountB);
    }


        // Get all balances of a user
    function getUserPortfolio(address user) external view returns (address[] memory tokens, uint256[] memory balances) {
        uint count = trackedTokens.length;
        tokens = new address[](count);
        balances = new uint256[](count);

        for (uint i = 0; i < count; i++) {
            address token = trackedTokens[i];
            tokens[i] = token;
            balances[i] = userBalances[user][token];
        }
    }


    // Get all balances held by contract
    function getContractPortfolio() external view returns (address[] memory tokens, uint256[] memory balances) {
        uint count = trackedTokens.length;
        tokens = new address[](count);
        balances = new uint256[](count);

        for (uint i = 0; i < count; i++) {
            address token = trackedTokens[i];
            tokens[i] = token;
            balances[i] = IERC20(token).balanceOf(address(this));
        }
    }

    
    function getContractBalance(address _token) external view returns (uint256) {
        uint8 decimals = IERC20Metadata(_token).decimals();
        return totalTokenBalance[_token] / (10 ** decimals);
    }

    // ---------------------------
    // Helpers
    // ---------------------------
    function _isTracked(address token) internal view returns (bool) {
        for (uint i = 0; i < trackedTokens.length; i++) {
            if (trackedTokens[i] == token) return true;
        }
        return false;
    }

    // ---------------------------------------------------------
    // Fallback
    // ---------------------------------------------------------
    fallback() external payable {}
    receive() external payable {}
}
