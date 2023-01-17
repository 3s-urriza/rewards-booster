// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "src/TheToken.sol";
import "src/BoosterPack.sol";

import { Pausable } from "@openzeppelin/security/Pausable.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/extensions/ERC4626.sol";

/// Errors
error Pool_RewardsMultiplierDoesNotExistError();
error Pool_WithdrawFeeDoesNotExistError();
error Pool_RewardMultipliersAmountZeroError();
error Pool_InitializeRewardMultipliersParametersFormatError();
error Pool_WithdrawFeesZeroAmountError();
error Pool_InitializeWithdrawFeesParametersFormatError();
error Pool_BlockNumberZeroError();
error Pool_RewardsMultiplierZeroError();
error Pool_WithdrawFeeZeroError();

abstract contract Pool is Pausable, Ownable, ERC4626 {
    /// @notice Struct to store the information about the Rewards Multiplier.
    struct RewardsMultiplier {
        uint64 blockNumber; // Block number of the RewardsMultiplier.
        uint64 multiplier; // Multiplier.
    }

    /// @notice Struct to store the information about the Withdraw Fees.
    struct WithdrawFee {
        uint64 blockNumber; // Block number of the WithdrawFee.
        uint64 fee; // Fee.
    }

    /// @notice Struct to store the information about the Deposits.
    struct DepositData {
        uint64 blockNumber; // Block number of the Deposit.
        uint128 amount; // Amount to be deposited.
    }

    /// @notice Struct to store the information about each User.
    struct UserData {
        uint64 accumRewards; // Accumulated rewards generated.
        uint64 accumRewardsBP; // Accumulated rewards generated from a Booster Pack.
        uint128 activeBoosterPack; // ID of the active Booster Pack of the User, if there is any.
        uint32 nextDepositIdToRemove; // Next Deposit to be removed.
        DepositData[] deposits; // Deposits of the User.
    }

    /// @notice Variable to store the base rate of tokens emitted per block.
    uint128 private _baseRateTokensPerBlock;

    /// @notice Variable to store the deposit fee.
    uint128 private _depositFee;

    /// @notice Variable to store the total amount deposited.
    uint128 private _totalAmount;

    /// @notice Array to store the Reward Multipliers.
    RewardsMultiplier[] private _rewardsMultipliers;

    /// @notice Array to store the Withdraw Fees.
    WithdrawFee[] private _withdrawFees;

    /// @notice Mapping to store the information from the Users.
    mapping(address => UserData) private _usersData;

    TheToken private _token;
    BoosterPack private _boosterPacks;

    // *** Modifiers ***

    /**
     * @dev Modifier that checks if a RewardsMultiplier exists
     * @param rewardsMultiplierId ID of the RewardsMultiplier
     */
    modifier rewardsMultiplierExists(uint32 rewardsMultiplierId) {
        require(_rewardsMultipliers.length > rewardsMultiplierId, "The RewardsMultiplier does not exist."); // TO-DO Custom Error Pool_RewardsMultiplierDoesNotExistError
        _;
    }

    /**
     * @dev Modifier that checks if a WithdrawFee exists
     * @param withdrawFeeId ID of the WithdrawFee
     */
    modifier withdrawFeeExists(uint32 withdrawFeeId) {
        require(_withdrawFees.length > withdrawFeeId, "The WithdrawFee does not exist."); // TO-DO Custom Error Pool_WithdrawFeeDoesNotExistError
        _;
    }

    constructor(
        address asset,
        uint32 baseRateTokensPerBlock,
        uint32 depositFee,
        uint64[] memory rewardsMultiplierBlocks,
        uint64[] memory rewardsMultipliers,
        uint64[] memory withdrawFeeBlocks,
        uint64[] memory withdrawFees
    ) ERC4626(IERC20(asset)) {
        /*
            CAUTION: When the vault is empty or nearly empty, deposits are at high risk of being stolen through frontrunning with
            a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
            attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
            deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
            similarly be affected by slippage. Users can protect against this attack as well unexpected slippage in general by
            verifying the amount received is as expected, using a wrapper that performs these checks such as
            https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
        */

        // Check if the length of the parameters it's the same, depending if it's for the RewardMultipliers or the WithdrawFees
        uint32 numberOfRewardMultipliers = uint32(rewardsMultiplierBlocks.length);
        require(numberOfRewardMultipliers != 0, "The RewardMultipliers quantities cannot be 0."); // TO-DO Custom Error Pool_RewardMultipliersAmountZeroError
        require(
            numberOfRewardMultipliers == rewardsMultipliers.length,
            "The RewardMultipliers quantities and the multipliers must have the same number of elements." // TO-DO Custom Error Pool_InitializeRewardMultipliersParametersFormatError
        );

        uint32 numberOfWithdrawFees = uint32(withdrawFeeBlocks.length);
        require(numberOfWithdrawFees != 0, "The WithdrawFees quantities cannot be 0."); // TO-DO Custom Error Pool_WithdrawFeesAmountZeroError
        require(
            numberOfWithdrawFees == withdrawFees.length,
            "The WithdrawFees quantities and the fees must have the same number of elements." // TO-DO Custom Error Pool_InitializeWithdrawFeesParametersFormatError
        );

        // Set the value of the _baseRateTokensPerBlock variable.
        _baseRateTokensPerBlock = baseRateTokensPerBlock;

        // Set the value of the _depositFeevariable variable.
        _depositFee = depositFee;

        // Initialize the _rewardsMultiplier array.
        _initializeRewardsMultipliers(rewardsMultiplierBlocks, rewardsMultipliers);

        // Initialize the _withdrawFees array.
        _initializeWithdrawFees(withdrawFeeBlocks, withdrawFees);
    }

    // *** Functions ***

    // *** External Functions ***

    /**
     * @dev Updates the _baseRateTokensPerBlock variable.
     * @param newBaseRateTokensPerBlock The new value.
     */
    function updateBaseRateTokensPerBlock(uint32 newBaseRateTokensPerBlock) external onlyOwner whenNotPaused {
        // Update the baseRateTokensPerBlock variable.
        _baseRateTokensPerBlock = newBaseRateTokensPerBlock;
    }

    /**
     * @dev Updates the _depositFee variable.
     * @param newDepositFee The new value.
     */
    function updateDepositFee(uint32 newDepositFee) external onlyOwner whenNotPaused {
        // Update the depositFee variable.
        _depositFee = newDepositFee;
    }

    /**
     * @dev Adds a new rewards multiplier.
     * @param blockNumber The block number value.
     * @param multiplier The multiplier value.
     */
    function addRewardsMultiplier(uint32 blockNumber, uint32 multiplier) external onlyOwner whenNotPaused {
        // Check if the parameters are correct
        require(blockNumber != 0, "ADD REWARDS MULTIPLIER: The RewardsMultiplier blockNumber cannot be 0."); // TO-DO Custom Error Pool_BlockNumberZeroError
        require(multiplier != 0, "ADD REWARDS MULTIPLIER: The RewardsMultiplier fee cannot be 0."); // TO-DO Custom Error Pool_RewardsMultiplierZeroError

        // Add the rewards multiplier.
        _rewardsMultipliers.push(RewardsMultiplier(blockNumber, multiplier));
    }

    /**
     * @dev Updates the rewards multiplier.
     * @param rewardsMultiplierId The ID of the rewardsMultiplier.
     * @param blockNumber The block number value.
     * @param multiplier The multiplier value.
     */
    function updateRewardsMultiplier(uint32 rewardsMultiplierId, uint32 blockNumber, uint32 multiplier)
        external
        onlyOwner
        whenNotPaused
        rewardsMultiplierExists(rewardsMultiplierId)
    {
        // Check if the parameters are correct
        require(blockNumber != 0, "UPDATE REWARDS MULTIPLIER: The RewardsMultiplier blockNumber cannot be 0."); // TO-DO Custom Error Pool_BlockNumberZeroError
        require(multiplier != 0, "UPDATE REWARDS MULTIPLIER: The RewardsMultiplier fee cannot be 0."); // TO-DO Custom Error Pool_RewardsMultiplierZeroError

        // Update the rewards multiplier.
        _rewardsMultipliers[rewardsMultiplierId].blockNumber = blockNumber;
        _rewardsMultipliers[rewardsMultiplierId].multiplier = multiplier;
    }

    /**
     * @dev Removes the rewards multiplier.
     * @param rewardsMultiplierId The ID of the rewardsMultiplier.
     */
    function removeRewardsMultiplier(uint32 rewardsMultiplierId)
        external
        onlyOwner
        whenNotPaused
        rewardsMultiplierExists(rewardsMultiplierId)
    {
        // Remove the rewards multiplier.
        delete _rewardsMultipliers[rewardsMultiplierId]; // TO-DO Check if leaving a gap could be avoidable or doesnt matter
    }

    /**
     * @dev Adds a new withdraw fee.
     * @param blockNumber The block number value.
     * @param fee The fee value.
     */
    function addWithdrawFee(uint32 blockNumber, uint32 fee) external onlyOwner whenNotPaused {
        // Check if the parameters are correct
        require(blockNumber != 0, "ADD WITHDRAW FEE: The WithdrawFee blockNumber cannot be 0."); // TO-DO Custom Error Pool_BlockNumberZeroError
        require(fee != 0, "ADD WITHDRAW FEE: The WithdrawFee fee cannot be 0."); // TO-DO Custom Error Pool_WithdrawFeeZeroError

        // Add the withdraw fee.
        _withdrawFees.push(WithdrawFee(blockNumber, fee));
    }

    /**
     * @dev Updates the withdraw fee.
     * @param withdrawFeeId The ID of the withdrawFee.
     * @param blockNumber The block number value.
     * @param fee The fee value.
     */
    function updateWithdrawFee(uint32 withdrawFeeId, uint32 blockNumber, uint32 fee)
        external
        onlyOwner
        whenNotPaused
        withdrawFeeExists(withdrawFeeId)
    {
        // Check if the parameters are correct
        require(blockNumber != 0, "UPDATE WITHDRAW FEE: The WithdrawFee blockNumber cannot be 0."); // TO-DO Custom Error Pool_BlockNumberZeroError
        require(fee != 0, "UPDATE WITHDRAW FEE: The WithdrawFee fee cannot be 0."); // TO-DO Custom Error Pool_WithdrawFeeZeroError

        // Update the withdraw fee.
        _withdrawFees[withdrawFeeId].blockNumber = blockNumber;
        _withdrawFees[withdrawFeeId].fee = fee;
    }

    /**
     * @dev Removes the withdraw fee.
     * @param withdrawFeeId The ID of the withdrawFee.
     */
    function removeWithdrawFee(uint32 withdrawFeeId)
        external
        onlyOwner
        whenNotPaused
        withdrawFeeExists(withdrawFeeId)
    {
        // Remove the withdraw fee.
        delete _withdrawFees[withdrawFeeId]; // TO-DO Check if leaving a gap could be avoidable or doesnt matter
    }

    /**
     * @dev Adds a new deposit.
     * @param amount.
     */
    function deposit(uint32 amount) external whenNotPaused {
        /*
            1. Adds the deposit.
            2. Charges the deposit fee into the recipient address.
        */
    }

    /**
     * @dev Withdraw a deposit.
     * @param depositId ID of the deposit.
     */
    function withdraw(uint32 depositId) external {
        /*
            1. Checks if the deposit exists.
            2. Withdraws the deposit (Taking into account the different deposits)
        */
    }

    /**
     * @dev Claims rewards for a specific deposit.
     * @param depositId ID of the deposit.
     */
    function claimRewards(uint32 depositId) external {
        /*
            1. Checks if the deposit exists.
            2. Check if there is any active Booster Pack.
            3. Set accumRewards to 0.
            4. Transfer the rewards to the depositor.
        */
    }

    /**
     * @dev Burns a Booster Pack amount.
     * @param id ID of the booster pack.
     */
    function burnBP(uint32 id) external {
        /*
            1. Checks if the sender is the owner of the NFT.
            2. Burns the Booster Pack.
            3. Set up the active Booster Pack to the user.
        */
    }

    /**
     * @dev Pauses the Pool.
     */
    function pausePool() external onlyOwner {
        /*
            1. Pauses the Pool.
        */
    }

    // *** Internal Functions ***

    /**
     * @dev Initializes the rewardsMultiplier array with the given parameters.
     * @param blockNumbers Block numbers of the rewardsMultipliers.
     * @param multipliers Multipliers of the rewardsMultipliers.
     */
    function _initializeRewardsMultipliers(uint64[] memory blockNumbers, uint64[] memory multipliers) internal {
        // Initialize the rewardsMultiplier array using the parameters.
        for (uint256 i = 0; i < blockNumbers.length; i++) {
            _rewardsMultipliers.push(RewardsMultiplier(blockNumbers[i], multipliers[i]));
        }
    }

    /**
     * @dev Initializes the withdrawFees array with the given parameters.
     * @param blockNumbers Block numbers of the withdrawFee.
     * @param fees Fees of the withdrawFee.
     */
    function _initializeWithdrawFees(uint64[] memory blockNumbers, uint64[] memory fees) internal {
        // Initialize the withdrawFee array with the parameters.
        for (uint256 i = 0; i < blockNumbers.length; i++) {
            _withdrawFees.push(WithdrawFee(blockNumbers[i], fees[i]));
        }
    }
}
