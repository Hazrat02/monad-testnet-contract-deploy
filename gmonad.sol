// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.24;
interface IERC20 {
    function transferFrom(address from, address to, uint amount) external returns (bool);
    function transfer(address to, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
}

contract Gmonad { 
    string public greeting;
    address public owner;
    uint256 public callFee = 0.001 ether; // fee to call setGreeting
     event Deposited(address indexed owner, address token, uint amount);

    constructor(string memory _greeting) payable {
        greeting = _greeting;
        owner = msg.sender;
    }

      modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }


    // Users must pay callFee to change the greeting
    function setGreeting(string calldata _greeting) external payable {
        require(msg.value >= callFee, "Insufficient fee sent");
        greeting = _greeting;
    }

    // Owner can withdraw collected fees
    function withdrawFees() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }

        // Owner deposits tokenB into contract
    function deposit(address token, uint amount) external onlyOwner {
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Deposit failed");
        emit Deposited(msg.sender, token, amount);
    }

}
