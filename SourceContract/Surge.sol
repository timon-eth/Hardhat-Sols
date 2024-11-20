// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Whitelist is OwnableUpgradeable {
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
    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IToken {
    function calculateTransferTaxes(address _from, uint256 _value) external view returns (uint256 adjustedValue, uint256 taxAmount);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function burn(uint256 _value) external;
}

contract Surge is Initializable, BEP20, Whitelist {
    using SafeMath for uint256;

    string public constant name = "Melta Liquidity Token";
    string public constant symbol = "DROPS";
    uint8 public constant decimals = 18;
    IToken internal token;
    BEP20 internal usdt;
    uint256 public totalTxs;
    uint256 internal lastBalance_;
    uint256 internal trackingInterval_;
    uint256 public providers;
    mapping (address => bool) internal _providers;
    mapping (address => uint256) internal _txs;
    bool public isPaused;
    event onTokenPurchase(address indexed buyer, uint256 indexed usdt_amount, uint256 indexed token_amount);
    event onUsdtPurchase(address indexed buyer, uint256 indexed token_amount, uint256 indexed usdt_amount);
    event onAddLiquidity(address indexed provider, uint256 indexed usdt_amount, uint256 indexed token_amount);
    event onRemoveLiquidity(address indexed provider, uint256 indexed usdt_amount, uint256 indexed token_amount);
    event onLiquidity(address indexed provider, uint256 indexed amount);
    event onContractBalance(uint256 balance);
    event onPrice(uint256 price);
    event onSummary(uint256 liquidity, uint256 price);

    function initialize(address usdt_addr, address token_addr) public initializer {
        __Ownable_init();

        isPaused = true;
        usdt = BEP20(usdt_addr);
        token = IToken(token_addr);
        lastBalance_= block.timestamp;
        trackingInterval_ = 1 minutes;
    }

    function unpause() public onlyOwner {
        isPaused = false;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    modifier isNotPaused() {
        require(!isPaused, "Swaps currently paused");
        _;
    }

    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve)  public view returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0, "INVALID_VALUE");
        uint256 input_amount_with_fee = input_amount.mul(990);
        uint256 numerator = input_amount_with_fee.mul(output_reserve);
        uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
        return numerator / denominator;
    }

    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve)  public view returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0,"input_reserve & output reserve must >0");
        uint256 numerator = input_reserve.mul(output_amount).mul(1000);
        uint256 denominator = (output_reserve.sub(output_amount)).mul(990);
        return (numerator / denominator).add(1);
    }

    function usdtToTokenInput(uint256 usdt_sold, uint256 min_tokens, address buyer, address recipient) private returns (uint256) {
        require(usdt_sold > 0 && min_tokens > 0, "sold and min 0");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 tokens_bought = getInputPrice(usdt_sold, usdt.balanceOf(address(this)).sub(usdt_sold), token_reserve);
        require(tokens_bought >= min_tokens, "tokens_bought >= min_tokens");

        require(usdt.transferFrom(buyer, address(this), usdt_sold), "DRIP to contract transfer failed; check balance and allowance, airdrop");
        require(token.transfer(recipient, tokens_bought), "transfer err");

        emit onTokenPurchase(buyer, usdt_sold, tokens_bought);
        emit onContractBalance(usdtBalance());
        trackGlobalStats();
        return tokens_bought;
    }

    function usdtToTokenSwapInput(uint256 usdt_sold, uint256 min_tokens) public isNotPaused returns (uint256) {
        return usdtToTokenInput(usdt_sold, min_tokens,msg.sender, msg.sender);
    }

    function tokenToUsdtInput(uint256 tokens_sold, uint256 min_usdt, address buyer, address recipient) private returns (uint256) {
        require(tokens_sold > 0 && min_usdt > 0,"tokens_sold > 0 && min_usdt > 0");
        uint256 token_reserve = token.balanceOf(address(this));
        (uint256 realized_sold, uint256 taxAmount) = token.calculateTransferTaxes(buyer, tokens_sold);
        uint256 usdt_bought = getInputPrice(realized_sold, token_reserve, usdt.balanceOf(address(this)));
        require(usdt_bought >= min_usdt,"usdt_bought >= min_usdt");

        require(usdt.transfer(recipient, usdt_bought), "transfer err");
        require(token.transferFrom(buyer, address(this), tokens_sold),"transforfrom error");

        emit onUsdtPurchase(buyer, tokens_sold, usdt_bought);
        trackGlobalStats();
        return usdt_bought;
    }

    function tokenToUsdtSwapInput(uint256 tokens_sold, uint256 min_usdt) public isNotPaused returns (uint256) {
        return tokenToUsdtInput(tokens_sold, min_usdt, msg.sender, msg.sender);
    }

    function trackGlobalStats() private {
        uint256 price = getUsdtToTokenOutputPrice(1e18);
        uint256 balance = usdtBalance();
        uint256 currentTime = block.timestamp;
        if (currentTime.sub(lastBalance_) > trackingInterval_) {
            emit onSummary(balance * 2, price);
            lastBalance_ = currentTime;
        }
        emit onContractBalance(balance);
        emit onPrice(price);
        totalTxs += 1;
        _txs[msg.sender] += 1;
    }

    function getUsdtToTokenInputPrice(uint256 usdt_sold) public view returns (uint256) {
        require(usdt_sold > 0,"usdt_sold > 0,,,1");
        uint256 token_reserve = token.balanceOf(address(this));
        return getInputPrice(usdt_sold, usdt.balanceOf(address(this)), token_reserve);
    }

    function getUsdtToTokenOutputPrice(uint256 tokens_bought) public view returns (uint256) {
        require(tokens_bought > 0,"tokens_bought > 0,,,1");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 usdt_sold = getOutputPrice(tokens_bought, usdt.balanceOf(address(this)), token_reserve);
        return usdt_sold;
    }

    function getTokenToUsdtInputPrice(uint256 tokens_sold) public view returns (uint256) {
        require(tokens_sold > 0, "token sold < 0,,,,,2");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 usdt_bought = getInputPrice(tokens_sold, token_reserve, usdt.balanceOf(address(this)));
        return usdt_bought;
    }

    function getTokenToUsdtOutputPrice(uint256 usdt_bought) public view returns (uint256) {
        require(usdt_bought > 0,"usdt_bought > 0,,,,2");
        uint256 token_reserve = token.balanceOf(address(this));
        return getOutputPrice(usdt_bought, token_reserve, usdt.balanceOf(address(this)));
    }

    function tokenAddress() public view returns (address) {
        return address(token);
    }

    function usdtBalance() public view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    function tokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getUsdtToLiquidityInputPrice(uint256 usdt_sold) public view returns (uint256) {
        require(usdt_sold > 0,"usdt_sold > 0,,,,,3");
        uint256 token_amount = 0;
        uint256 total_liquidity = _totalSupply;
        uint256 usdt_reserve = usdt.balanceOf(address(this));
        uint256 token_reserve = token.balanceOf(address(this));
        token_amount = (usdt_sold.mul(token_reserve) / usdt_reserve).add(1);
        uint256 liquidity_minted = usdt_sold.mul(total_liquidity) / usdt_reserve;
        return liquidity_minted;
    }

    function getLiquidityToReserveInputPrice(uint amount) public view returns (uint256, uint256) {
        uint256 total_liquidity = _totalSupply;
        require(total_liquidity > 0,"total_liquidity > 0,,,,1");
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 usdt_amount = amount.mul(usdt.balanceOf(address(this))) / total_liquidity;
        uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
        return (usdt_amount, token_amount);
    }

    function txs(address owner) public view returns (uint256) {
        return _txs[owner];
    }

    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 max_usdt) isNotPaused public returns (uint256) {
        require(max_tokens > 0 && max_usdt > 0, "Swap#addLiquidity: INVALID_ARGUMENT");
        uint256 total_liquidity = _totalSupply;
        uint256 token_amount = 0;
        if (_providers[msg.sender] == false){
            _providers[msg.sender] = true;
            providers += 1;
        }
        if (total_liquidity > 0) {
            require(min_liquidity > 0,"min_liquidity > 0,,,,4");
            uint256 usdt_reserve = usdt.balanceOf(address(this)).sub(max_usdt);
            uint256 token_reserve = token.balanceOf(address(this));
            token_amount = (max_usdt.mul(token_reserve) / usdt_reserve).add(1);
            uint256 liquidity_minted = max_usdt.mul(total_liquidity) / usdt_reserve;
            require(max_tokens >= token_amount && liquidity_minted >= min_liquidity,"max_tokens >= token_amount && liquidity_minted >= min_liquidity,,,,1");
            _balances[msg.sender] = _balances[msg.sender].add(liquidity_minted);
            _totalSupply = total_liquidity.add(liquidity_minted);
            require(token.transferFrom(msg.sender, address(this), token_amount),"transfrom4 error");
            require(usdt.transferFrom(msg.sender, address(this), token_amount),"usdt transfrom error");
            emit onAddLiquidity(msg.sender, max_usdt, token_amount);
            emit onLiquidity(msg.sender, _balances[msg.sender]);
            emit Transfer(address(0), msg.sender, liquidity_minted);
            return liquidity_minted;
        } else {
            require(max_usdt >= 1e18, "INVALID_VALUE");
            token_amount = max_tokens;
            uint256 initial_liquidity = usdt.balanceOf(address(this));
            _totalSupply = initial_liquidity;
            _balances[msg.sender] = initial_liquidity;
            require(token.transferFrom(msg.sender, address(this), token_amount),"transforfrom 5 error");
            require(usdt.transferFrom(msg.sender, address(this), token_amount),"usdt transfrom error");
            emit onAddLiquidity(msg.sender, max_usdt, token_amount);
            emit onLiquidity(msg.sender, _balances[msg.sender]);
            emit Transfer(address(0), msg.sender, initial_liquidity);
            return initial_liquidity;
        }
    }

    function removeLiquidity(uint256 amount, uint256 min_usdt, uint256 min_tokens) onlyWhitelisted public returns (uint256, uint256) {
        require(amount > 0 && min_usdt > 0 && min_tokens > 0,"amount > 0 && min_usdt > 0 && min_tokens > 0,333");
        uint256 total_liquidity = _totalSupply;
        require(total_liquidity > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 usdt_amount = amount.mul(usdt.balanceOf(address(this))) / total_liquidity;
        uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
        require(usdt_amount >= min_usdt && token_amount >= min_tokens,"(usdt_amount >= min_usdt && token_amount >= min_tokens,33");
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _totalSupply = total_liquidity.sub(amount);
        payable(msg.sender).transfer(usdt_amount);
        require(token.transfer(msg.sender, token_amount),"transfer error");
        emit onRemoveLiquidity(msg.sender, usdt_amount, token_amount);
        emit onLiquidity(msg.sender, _balances[msg.sender]);
        emit Transfer(msg.sender, address(0), amount);
        return (usdt_amount, token_amount);
    }
}