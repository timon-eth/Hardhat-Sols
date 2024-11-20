// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

// OpenZeppelin dependencies
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Vesting
 * @dev A contract for token vesting that supports cliff, duration, slice periods, and revocability.
 */
contract Vesting is Ownable, ReentrancyGuard {
    struct VestingSchedule {
        address beneficiary; // Beneficiary of the tokens after they are released
        uint256 cliff;       // Time until the first release of tokens (cliff in seconds)
        uint256 start;       // Start time of the vesting period
        uint256 launch;      // Time of the Token Generation Event (TGE)
        uint256 duration;    // Total duration of the vesting period
        uint256 slicePeriodSeconds; // Duration of each slice period for token release
        bool revocable;      // Whether the vesting schedule is revocable
        uint256 amountTotal; // Total amount of tokens to be released
        uint256 launchPercent; // Percentage of tokens to be released at TGE
        uint256 released;    // Amount of tokens released so far
        bool revoked;        // Whether the vesting schedule has been revoked
    }

    IERC20 public immutable token; // The token being vested

    bytes32[] private vestingSchedulesIds; // List of all vesting schedule IDs
    mapping(bytes32 => VestingSchedule) private vestingSchedules; // Mapping of schedule IDs to vesting schedules
    uint256 private vestingSchedulesTotalAmount; // Total amount of tokens reserved for vesting
    mapping(address => uint256) private holdersVestingCount; // Mapping to track number of vesting schedules per holder

    // Event emitted when a new vesting schedule is created
    event VestingScheduleCreated(
        bytes32 indexed vestingScheduleId,
        address indexed beneficiary,
        uint256 amountTotal,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 slicePeriodSeconds,
        uint256 launchPercent
    );

    // Event emitted when tokens are released
    event TokensReleased(address indexed beneficiary, uint256 amount);

    // Event emitted when a vesting schedule is revoked
    event VestingRevoked(bytes32 indexed vestingScheduleId);

    /**
     * @dev Reverts if the vesting schedule does not exist or has been revoked.
     */
    modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
        require(!vestingSchedules[vestingScheduleId].revoked, "Vesting: schedule has been revoked");
        _;
    }

    /**
     * @dev Constructor to initialize the contract with the token address.
     * @param token_ Address of the ERC20 token contract
     */
    constructor(address token_) Ownable() {
        require(token_ != address(0), "Vesting: invalid token address");
        token = IERC20(token_);
    }

    /**
     * @dev Fallback function for plain Ether transfers.
     */
    receive() external payable {}

    /**
     * @dev Fallback function for unrecognized calls.
     */
    fallback() external payable {}

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     * @param _beneficiary Address of the beneficiary to whom the vested tokens are transferred
     * @param _start Start time of the vesting period
     * @param _cliff Duration of the cliff period in seconds
     * @param _launch Start time of the Token Generation Event (TGE)
     * @param _duration Total duration of the vesting period in seconds
     * @param _slicePeriodSeconds Duration of each slice period in seconds
     * @param _launchPercent Percentage of tokens to be released at TGE (must be between 0 and 100)
     * @param _revocable Whether the vesting schedule is revocable or not
     * @param _amount Total amount of tokens to be vested
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _launch,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _launchPercent,
        bool _revocable,
        uint256 _amount
    ) external onlyOwner {
        require(getWithdrawableAmount() >= _amount, "Vesting: insufficient tokens");
        require(_duration > 0, "Vesting: duration must be greater than 0");
        require(_launch > 0, "Vesting: launch must be greater than 0");
        require(_amount > 0, "Vesting: amount must be greater than 0");
        require(_slicePeriodSeconds >= 1, "Vesting: slicePeriodSeconds must be >= 1");
        require(_launchPercent <= 100, "Vesting: launchPercent must be between 0 and 100");

        bytes32 vestingScheduleId = keccak256(abi.encodePacked(_beneficiary, _start, _cliff, _duration, block.timestamp));
        
        VestingSchedule memory schedule = VestingSchedule({
            beneficiary: _beneficiary,
            cliff: _cliff,
            start: _start,
            launch: _launch,
            duration: _duration,
            slicePeriodSeconds: _slicePeriodSeconds,
            revocable: _revocable,
            amountTotal: _amount,
            launchPercent: _launchPercent,
            released: 0,
            revoked: false
        });

        vestingSchedules[vestingScheduleId] = schedule;
        vestingSchedulesIds.push(vestingScheduleId);
        holdersVestingCount[_beneficiary]++;

        emit VestingScheduleCreated(vestingScheduleId, _beneficiary, _amount, _start, _cliff, _duration, _slicePeriodSeconds, _launchPercent);
    }

    /**
     * @dev Revokes a vesting schedule, preventing any future token releases.
     * @param vestingScheduleId ID of the vesting schedule to revoke
     */
    function revokeVestingSchedule(bytes32 vestingScheduleId) external onlyOwner {
        VestingSchedule storage schedule = vestingSchedules[vestingScheduleId];
        require(schedule.revocable, "Vesting: schedule is not revocable");
        require(!schedule.revoked, "Vesting: schedule already revoked");

        schedule.revoked = true;
        emit VestingRevoked(vestingScheduleId);
    }

    /**
     * @dev Calculates how many tokens are releasable for a specific vesting schedule.
     * @param schedule The vesting schedule
     * @return The amount of tokens that can be released
     */
    function calculateReleasable(VestingSchedule memory schedule) public view returns (uint256) {
        if (block.timestamp < schedule.start + schedule.cliff) {
            return 0; // Tokens are locked until the cliff is reached
        }

        uint256 elapsedTime = block.timestamp - schedule.start;
        uint256 totalSlices = elapsedTime / schedule.slicePeriodSeconds;

        if (totalSlices * schedule.slicePeriodSeconds > schedule.duration) {
            totalSlices = schedule.duration / schedule.slicePeriodSeconds; // Make sure not to exceed the vesting duration
        }

        uint256 releasableAmount = (schedule.amountTotal * totalSlices) / (schedule.duration / schedule.slicePeriodSeconds);
        uint256 launchRelease = (schedule.amountTotal * schedule.launchPercent) / 100;

        // Launch release logic: Add launch release if TGE is completed
        if (block.timestamp >= schedule.launch) {
            releasableAmount += launchRelease;
        }

        return releasableAmount - schedule.released;
    }

    /**
     * @dev Releases tokens for the caller if they are the beneficiary of a vesting schedule.
     * @param vestingScheduleId The vesting schedule ID to release tokens from
     */
    function release(bytes32 vestingScheduleId) external nonReentrant onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
        VestingSchedule storage schedule = vestingSchedules[vestingScheduleId];
        require(schedule.beneficiary == msg.sender, "Vesting: caller is not the beneficiary");

        uint256 releasable = calculateReleasable(schedule);
        require(releasable > 0, "Vesting: no tokens to release");

        schedule.released += releasable;
        require(token.transfer(schedule.beneficiary, releasable), "Vesting: token transfer failed");

        emit TokensReleased(schedule.beneficiary, releasable);
    }

    /**
     * @dev Returns the amount of withdrawable tokens in the contract.
     * @return The amount of withdrawable tokens
     */
    function getWithdrawableAmount() public view returns (uint256) {
        return token.balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }
}
