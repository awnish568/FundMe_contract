// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error NotOwner();
error alreadyFunder();

contract FundMe {
    uint256 public constant MINIMUM_ETHER = 1;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;

    constructor() {
        owner = msg.sender;
    }


    function fund() public payable {
        // 3.As the chainlink intergation is removed so we are no longer able to convert
        // ether to USD so we will verify the funder directly by minimum ether funded by them
        require(msg.value >= MINIMUM_ETHER, "Didn't send enough!");

        // 1. following loop will ensure unique addresses in the Funders Array
        for (uint256 funderIndex = 0; funderIndex < funders.length;funderIndex++) {
            if (msg.sender == funders[funderIndex]) revert alreadyFunder();
        }

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

   
    // 2. through following function the current owner of the contract can transfer the 
    // ownership to the address which is passed to this function
    // NOTE - now we can't declare the variable owner as immutable as it may be changed again
    function changeOwnership(address newowner) public onlyOwner {
        for (uint256 funderIndex = 0;funderIndex < funders.length;funderIndex++) {
            if (funders[funderIndex] == newowner) {
                owner = newowner;
                break;
            }
        }
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0;funderIndex < funders.length;funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}
