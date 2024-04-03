// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenVesting {
    // Define a struct to hold vesting details for a beneficiary
    struct VestingSchedule {
        uint256 start; // Timestamp when vesting starts
        uint256 cliffDuration; // Duration of the cliff in seconds
        uint256 totalDuration; // Total duration of vesting in seconds
        uint256 amountTotal; // Total amount of tokens to be vested
        uint256 amountReleasedAtStart; // Amount to be released at the start
        uint256 amountReleasedAtCliff; // Amount to be released after the cliff
        uint256 amountReleasedPerMonth; // Amount to be released monthly after the cliff
        uint256 amountClaimed; // Amount that has been claimed
    }

    // ERC20 basic token contract being held
    IERC20 private _token;

    // Mapping from beneficiary to their vesting schedule
    mapping(address => VestingSchedule) private _vestingSchedules;

    event TokensReleased(address beneficiary, uint256 amount);

    // Constructor takes the token address that is being vested
    constructor(IERC20 tokenAddress) {
        _token = tokenAddress;
    }

    // Add a vesting schedule for a beneficiary
    function addVestingSchedule(
        address beneficiary,
        uint256 startTimestamp,
        uint256 cliffDurationInSeconds,
        uint256 totalVestingDurationInSeconds,
        uint256 totalAmount,
        uint256 releaseAtStartPercentage,
        uint256 releaseAtCliffPercentage,
        uint256 linearReleasePercentage
    ) external {
        require(beneficiary != address(0), "Vesting: beneficiary is the zero address");
        require(_vestingSchedules[beneficiary].amountTotal == 0, "Vesting: schedule already exists");

        // Calculate amounts based on percentages
        uint256 amountAtStart = (totalAmount * releaseAtStartPercentage) / 100;
        uint256 amountAtCliff = (totalAmount * releaseAtCliffPercentage) / 100;
        // Assuming the remainder is released linearly monthly after the cliff
        uint256 amountPerMonth = (totalAmount * linearReleasePercentage) / 100 / (totalVestingDurationInSeconds / 30 days);

        _vestingSchedules[beneficiary] = VestingSchedule({
            start: startTimestamp,
            cliffDuration: cliffDurationInSeconds,
            totalDuration: totalVestingDurationInSeconds,
            amountTotal: totalAmount,
            amountReleasedAtStart: amountAtStart,
            amountReleasedAtCliff: amountAtCliff,
            amountReleasedPerMonth: amountPerMonth,
            amountClaimed: 0
        });
    }

    // Claim vested tokens
    function claim(address beneficiary) external {
        VestingSchedule storage schedule = _vestingSchedules[beneficiary];
        require(schedule.amountTotal > 0, "Vesting: no schedule");

        uint256 unreleased = _releasableAmount(beneficiary);

        require(unreleased > 0, "Vesting: no tokens are due");

        schedule.amountClaimed += unreleased;

        _token.transfer(beneficiary, unreleased);

        emit TokensReleased(beneficiary, unreleased);
    }

    // Calculate the amount that has already vested but hasn't been claimed yet.
    function _releasableAmount(address beneficiary) private view returns (uint256) {
        VestingSchedule storage schedule = _vestingSchedules[beneficiary];
        uint256 vestedAmount = _vestedAmount(schedule);
        return vestedAmount - schedule.amountClaimed;
    }

    // Calculate the vested amount at the current time
    function _vestedAmount(VestingSchedule memory schedule) private view returns (uint256) {
        if (block.timestamp < schedule.start) {
            return 0;
        } else if (block.timestamp >= schedule.start + schedule.totalDuration) {
            return schedule.amountTotal;
        } else if (block.timestamp < schedule.start + schedule.cliffDuration) {
            return schedule.amountReleasedAtStart;
        } else {
            // Calculate the amount released monthly after the cliff
            uint256 monthsAfterCliff = (block)