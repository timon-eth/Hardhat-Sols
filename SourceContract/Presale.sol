// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow!");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract BEP20 {
    using SafeMath for uint256;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    uint256 internal _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0),"to address will not be 0");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
    function _mint(address account, uint256 value) internal {
        require(account != address(0),"2");
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }
    function _burn(address account, uint256 value) internal {
        require(account != address(0),"3");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0),"4");
        require(owner != address(0),"5");
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

interface IToken {
    function remainingMintableSupply() external view returns (uint256);

    function calculateTransferTaxes(address _from, uint256 _value) external view returns (uint256 adjustedValue, uint256 taxAmount);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function mintedSupply() external returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function whitelist(address addrs) external returns (bool);

    function addAddressesToWhitelist(address[] memory addrs) external returns (bool success);
}

contract Presale is Initializable {
    using SafeMath for uint256;
    IToken public token;
    BEP20 public usdt;
    uint256 public presalePrice; // 17647058823529400
    address payable public owner;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public limit;
    uint256 public limitperwallet; // 750000000000000000000
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    function initialize(address usdt_addr, address token_addr) public initializer {
        token = IToken(token_addr);
        usdt = BEP20(usdt_addr);
        owner = payable(msg.sender);
        limitperwallet = 750000000000000000000;
        presalePrice = 17647058823529400;
        paused = false;
    }

    modifier onlyowner() {
        require(owner == msg.sender, 'you are not owner');
        _;
    }

    event Pause();
    event Unpause();

    bool public paused;
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'not whitelisted!');
        _;
    }

    function pause() onlyowner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function unpause() onlyowner whenPaused public {
        paused = false;
        emit Unpause();
    }

    function calculateMeltaforWT(uint256 amount) public view returns (uint256) {
        return (presalePrice.mul(amount));
    }

    function Buy(uint256 _amountUsdt) public whenNotPaused onlyWhitelisted {
        require(usdt.transferFrom(msg.sender, address(this), _amountUsdt), "usdt token contract transfer failed; check balance and allowance, presale");
        uint256 amount = _amountUsdt.div(presalePrice);
        require(limit[msg.sender].add(amount) <= limitperwallet, "Limit exceeded");

        token.transfer(msg.sender, amount);
        limit[msg.sender] += amount;
    }

    function addAddressToWhitelist(address addr) onlyowner public returns (bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    function addAddressesToWhitelist(address[] memory addrs) onlyowner public returns (bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    function checkContractBalance() public view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    function WithdrawUsdt(uint256 amount, address to) public onlyowner {
        require(checkContractBalance() >= amount, "contract have not enough balance");
        usdt.transfer(to, amount);
    }

    function WithdrawMelta(uint256 amount) public onlyowner {
        token.transfer(address(msg.sender), amount);
    }

    function updatePresalePrice(uint256 amount) public onlyowner {
        presalePrice = amount;
    }

    function updateWalletLimit(uint256 amount) public onlyowner {
        limitperwallet = amount;
    }
}