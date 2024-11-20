// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Whitelist is OwnableUpgradeable  {
    mapping(address => bool) public whitelist;
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'not whitelisted!');
        _;
    }

    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }
    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}
interface IToken {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}


contract Vault is Initializable, Whitelist {
    IToken internal token; 

        function initialize(address token_addr) public initializer {
        token = IToken(token_addr);
         __Ownable_init();
    }
 //   constructor(address token_addr) public{
 //       token = IToken(token_addr);
 //   }

    address public devAddr;
    
    function setDevAddr(address newDevAddr) public onlyOwner {
        devAddr = newDevAddr;

    }

    function withdraw(uint256 _amount) public onlyWhitelisted {
        require(token.transfer(msg.sender, _amount));
    }

    function withdrawWithFee(uint256 _amount) public onlyWhitelisted {
        require(token.transfer(msg.sender, _amount / 100 * 70));
        require(token.transfer(devAddr, _amount / 100 * 30));
   
    }
}