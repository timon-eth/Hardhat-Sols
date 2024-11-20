/**
 *Submitted for verification at BscScan.com on 2022-04-07
*/

// SPDX-License-Identifier: MIT

/*   BNBsmartswap - investment platform based on Binance Smart Chain blockchain smart-contract technology. Safe and legit!

*
*   [USAGE INSTRUCTION]
*
*   1) Connect browser extension Metamask (see help: https://medium.com/stakingbits/setting-up-metamask-for-polygon-BNB-network-838058f6d844 )
*   2) Choose one of the tariff plans, enter the BNB amount (.01 BNB minimum) using our website "Stake BNB" button
*   3) Wait for your earnings
*   4) Withdraw earnings any time using our website "Withdraw" button
*
*   [INVESTMENT CONDITIONS]
*
*   - Basic interest rate: +20% every 24 hours (~0.83% hourly) - only for new deposits
*   - Minimal deposit: 0.01 BNB
*   - Maximal deposit: 100 BNB
*   - Total income: based on your tarrif plan (20% daily!!!) + Basic interest rate !!!
*   - Earnings every moment, withdraw any time (if you use capitalization of interest you can withdraw only after end of your deposit)
*
*   [AFFILIATE PROGRAM]
*
*   - 3-level referral commission: 12% - 8% - 3%
*
*   [FUNDS DISTRIBUTION]
*
*   - 82% Platform main balance, participants payouts
*   - 8% Advertising and promotion expenses
*   - 8% Affiliate program bonuses
*   - 2% Support work, technical functioning, administration fee
*/

pragma solidity 0.8.7;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */


contract BNBsmartswap {
    using SafeMath for uint256;
    uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;  // Set to minimum investment amount
    uint256 constant private INVEST_MAX_AMOUNT = 100 ether;  // Set to maximum investment amount
    uint256[] public REFERRAL_PERCENTS = [12, 8, 3];
    uint256 constant public CEO_FEE = 9;//9%
    uint256 constant public DEV_FEE = 1;//1%
    uint256 constant public WITHDRAW_FEE = 10; //In base point
    uint256 constant public PERCENTS_DIVIDER = 100;
    uint256 constant public TIME_STEP = 1 days;

    uint256 constant public PERCENT_STEP_ONE = 22;
    uint256 constant public PERCENT_STEP_TWO = 25;
    uint256 constant public PERCENT_STEP_THREE = 28;
    uint256 constant public PERCENT_STEP_FOUR = 31;
    uint256 constant public PERCENT_STEP_FIVE = 35;
    uint256 constant public PERCENT_STEP_SIX = 40;
    uint256 constant public PERCENT_STEP_SEVEN = 46;
    uint256 constant public PERCENT_STEP_EIGHT = 53;

    address public owner;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 percent;
        uint256 amount;
        uint256 profit;
        uint256 start;
        uint256 finish;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256[3] levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 totalStaked;
    }

    mapping (address => User) internal users;
    uint256 public startUNIX;
    address payable public commissionWallet;
    address payable public devWallet;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable wallet, address payable devA, uint256 startDate) {
        require(!isContract(wallet));
        require(startDate > 0);
        owner = msg.sender;
        commissionWallet = wallet;
        devWallet = devA;
        startUNIX = startDate;
        plans.push(Plan(7, 200));
    }
    // A mapping to store the balances of each address
    mapping(address => uint) public balances;

    // A function to deposit money to the contract
    function deposit(address reffer, uint8 plan) public payable {
        require(block.timestamp > startUNIX, "Not started yet");
        require(msg.value >= INVEST_MIN_AMOUNT, "Must deposit more than 0.05");
        require(msg.value <= INVEST_MAX_AMOUNT, "Must deposit less than 100");
        //        require(plan < 1, "Invalid plan");

        uint256 ceofee = msg.value.mul(CEO_FEE).div(WITHDRAW_FEE);
        uint256 devfee = msg.value.mul(DEV_FEE).div(WITHDRAW_FEE);
        commissionWallet.transfer(ceofee);
        devWallet.transfer(devfee);

        emit FeePayed(msg.sender, ceofee.add(devfee));

        User storage user = users[msg.sender];
        if (user.referrer == address (0)){
            if(users[reffer].deposits.length > 0 && reffer != msg.sender){
                user.referrer = reffer;
            }
            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }
        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }
        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}