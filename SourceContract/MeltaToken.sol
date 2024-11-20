// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract Whitelist is OwnableUpgradeable {
    mapping(address => bool) public whitelist;
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'not whitelisted');
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

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MintableToken is ERC20Upgradeable, Whitelist {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address _to, uint256 _amount) virtual onlyWhitelisted canMint public returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function openMinting() virtual onlyWhitelisted public returns (bool) {
        mintingFinished = false;
        return true;
    }

    function finishMinting() virtual onlyWhitelisted canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract MeltaToken is MintableToken {
    using SafeMath for uint256;

    struct Stats {
        uint256 txs;
        uint256 minted;
    }
    uint256 public constant MAX_INT = 2**256 - 1;
    uint256 public constant targetSupply = MAX_INT;
    uint256 public totalTxs;
    uint256 public players;
    uint256 private mintedSupply_;
    mapping(address => Stats) private stats;
    address public vaultAddress;
    uint8 constant internal taxDefault = 10;
    mapping (address => uint8) private _customTaxRate;
    mapping (address => bool) private _hasCustomTax;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    event TaxPayed(address from, address vault, uint256 amount);

    function initialize(uint256 _initialMint) public initializer {
        __ERC20_init("Melta Token", "MTA");
        __Ownable_init();

        mintingFinished = false;
        addAddressToWhitelist(owner());
        mint(owner(), _initialMint * 1e18);
        removeAddressFromWhitelist(owner());
    }

    function setVaultAddress(address _newVaultAddress) public onlyOwner {
        vaultAddress = _newVaultAddress;
    }

    function mint(address _to, uint256 _amount) override public returns (bool) {
        if (_amount == 0 || mintedSupply_.add(_amount) > targetSupply) {
            return false;
        }
        super.mint(_to, _amount);
        mintedSupply_ = mintedSupply_.add(_amount);
        if (mintedSupply_ == targetSupply) {
            mintingFinished = true;
            emit MintFinished();
        }
        if (stats[_to].txs == 0) {
            players += 1;
        }
        stats[_to].txs += 1;
        stats[_to].minted += _amount;
        totalTxs += 1;
        return true;
    }

    function finishMinting() override onlyOwner canMint public returns (bool) {
        return false;
    }

    function calculateTransactionTax(uint256 _value, uint8 _tax) internal returns (uint256 adjustedValue, uint256 taxAmount) {
        taxAmount = _value.mul(_tax).div(100);
        adjustedValue = _value.mul(SafeMath.sub(100, _tax)).div(100);
        return (adjustedValue, taxAmount);
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool) {
        (uint256 adjustedValue, uint256 taxAmount) = calculateTransferTaxes(_from, _value);
        if (taxAmount > 0){
            require(super.transferFrom(_from, vaultAddress, taxAmount));
            emit TaxPayed(_from, vaultAddress, taxAmount);
        }
        require(super.transferFrom(_from, _to, adjustedValue));
        if (stats[_to].txs == 0) {
            players += 1;
        }
        stats[_to].txs += 1;
        stats[_from].txs += 1;
        totalTxs += 1;
        return true;
    }

    function transfer(address _to, uint256 _value) override public returns (bool) {
        (uint256 adjustedValue, uint256 taxAmount) = calculateTransferTaxes(msg.sender, _value);
        if (taxAmount > 0){
            require(super.transfer(vaultAddress, taxAmount));
            emit TaxPayed(msg.sender, vaultAddress, taxAmount);
        }
        require(super.transfer(_to, adjustedValue));
        if (stats[_to].txs == 0) {
            players += 1;
        }
        stats[_to].txs += 1;
        stats[msg.sender].txs += 1;
        totalTxs += 1;
        return true;
    }

    function calculateTransferTaxes(address _from, uint256 _value) public returns (uint256 adjustedValue, uint256 taxAmount) {
        adjustedValue = _value;
        taxAmount = 0;
        if (!_isExcluded[_from]) {
            uint8 taxPercent = taxDefault; 
            if (_hasCustomTax[_from]){
                taxPercent = _customTaxRate[_from];
            }
           (adjustedValue, taxAmount) = calculateTransactionTax(_value, taxPercent);
        }
        return (adjustedValue, taxAmount);
    }

    function remainingMintableSupply() public view returns (uint256) {
        return targetSupply.sub(mintedSupply_);
    }

    function cap() public view returns (uint256) {
        return targetSupply;
    }

    function mintedSupply() public view returns (uint256) {
        return mintedSupply_;
    }

    function statsOf(address player) public view returns (uint256, uint256, uint256) {
        return (balanceOf(player), stats[player].txs, stats[player].minted);
    }

    function mintedBy(address player) public view returns (uint256) {
        return stats[player].minted;
    }

    function setAccountCustomTax(address account, uint8 taxRate) external onlyOwner() {
        require(taxRate >= 0 && taxRate <= 100, "Invalid tax amount");
        _hasCustomTax[account] = true;
        _customTaxRate[account] = taxRate;
    }

    function removeAccountCustomTax(address account) external onlyOwner() {
        _hasCustomTax[account] = false;
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded!");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _isExcluded[account] = false;
                delete _excluded[_excluded.length - 1];
                break;
            }
        }
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
}