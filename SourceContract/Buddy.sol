// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BuddySystem is Initializable {

    event onUpdateBuddy(address indexed player, address indexed buddy);
    mapping(address => address) private buddies;
    address payable public owner;
    
    function initialize() public initializer {
       owner = payable(msg.sender);
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, 'you are not owner');
        _;
    }

    function updateBuddy(address buddy) public {
        buddies[msg.sender] = buddy;
        emit onUpdateBuddy(msg.sender, buddy);
    }

    function updateBuddyFromPresale(address buddy, address _buddies) public onlyOwner {
          buddies[_buddies] = buddy;
        emit onUpdateBuddy(_buddies, buddy);
    }

    function myBuddy() public view returns (address) {
        return buddyOf(msg.sender);
    }
    
    function buddyOf(address player) public view returns (address) {
        return buddies[player];
    }
}