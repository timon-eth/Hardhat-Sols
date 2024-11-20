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

contract BNBsmartswap  {
    using SafeMath for uint256;

    uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;  // Set to minimum investment amount
    uint256 constant private INVEST_MAX_AMOUNT = 100 ether;  // Set to maximum investment amount
    uint256[] public REFERRAL_PERCENTS = [120, 80, 30];
    uint256 constant public CEO_FEE = 80;
    uint256 constant public DEV_FEE = 10;
    uint256 constant public ETC_FEE = 10;
    uint256 constant public PERCENT_STEP = 5;
    uint256 constant public WITHDRAW_FEE = 1000; //In base point
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public totalStaked;
    uint256 public totalRefBonus;

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
    address payable public etcWallet;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable wallet, address payable devAddr, address payable etcAddr, uint256 startDate) {
        require(!isContract(wallet));
        require(startDate > 0);
        owner = msg.sender;
        commissionWallet = wallet;
        devWallet = devAddr;
        etcWallet = etcAddr;
        startUNIX = startDate;
        plans.push(Plan(7, 200));
    }

    function invest(address referrer, uint8 plan) public payable {
        require(block.timestamp > startUNIX, "Not started yet");
        require(msg.value >= INVEST_MIN_AMOUNT, "Must deposit more than 0.05");
        require(msg.value <= INVEST_MAX_AMOUNT, "Must deposit less than 100");
        require(plan < 1, "Invalid plan");

        uint256 ceofee = msg.value.mul(CEO_FEE).div(PERCENTS_DIVIDER);
        uint256 devfee = msg.value.mul(DEV_FEE).div(PERCENTS_DIVIDER);
        uint256 etcfee = msg.value.mul(ETC_FEE).div(PERCENTS_DIVIDER);
        commissionWallet.transfer(ceofee);
        devWallet.transfer(devfee);
        etcWallet.transfer(etcfee);
        emit FeePayed(msg.sender, ceofee.add(devfee).add(etcfee));

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
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

        (uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
        user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

        totalStaked = totalStaked.add(msg.value);
        emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 fees = totalAmount.mul(WITHDRAW_FEE).div(10000);
        totalAmount = totalAmount.sub(fees);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        users[msg.sender].totalStaked += totalAmount;

        user.checkpoint = block.timestamp;

        payable(msg.sender).transfer(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getPercent(uint8 plan) public view returns (uint256) {
        if (block.timestamp > startUNIX) {
            return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
        } else {
            return plans[plan].percent;
        }
    }

    function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
        percent = getPercent(plan);

        if (plan < 3) {
            profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
        } else if (plan < 6) {
            for (uint256 i = 0; i < plans[plan].time; i++) {
                profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
            }
        }

        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.checkpoint < user.deposits[i].finish) {
                if (user.deposits[i].plan < 3) {
                    uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
                    uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                    uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
                    if (from < to) {
                        totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                    }
                } else if (block.timestamp > user.deposits[i].finish) {
                    totalAmount = totalAmount.add(user.deposits[i].profit);
                }
            }
        }

        return totalAmount;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
        return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getUserTotalStaked(address userAddress) public view returns(uint256) {
        return users[userAddress].totalStaked;
    }

    function getUserTotalClaim(address userAddress) public view returns(uint256) {
        uint256 totalClaim = 0;
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            (, uint256 amount, ) = getResult(0, users[userAddress].deposits[i].amount);
            totalClaim += amount;
        }
        return totalClaim;
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        profit = user.deposits[index].profit;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function transferOwnerShip (address _newOwner) public {
        require (msg.sender == owner, "you are not a owner of this contract");
        owner = _newOwner;
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

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
}