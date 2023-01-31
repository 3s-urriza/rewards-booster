// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "src/interfaces/IPool.sol";
import "src/TheToken.sol";
import "src/BoosterPack.sol";

import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/security/ReentrancyGuard.sol";
import "@openzeppelin/utils/math/Math.sol";
import "@openzeppelin/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/utils/introspection/ERC165.sol";

/// Errors
error Pool_RewardsMultiplierDoesNotExistError();
error Pool_WithdrawFeeDoesNotExistError();
error Pool_RewardMultipliersAmountZeroError();
error Pool_InitializeRewardMultipliersParametersFormatError();
error Pool_WithdrawFeesAmountZeroError();
error Pool_InitializeWithdrawFeesParametersFormatError();
error Pool_BlockNumberZeroError();
error Pool_RewardsMultiplierZeroError();
error Pool_WithdrawFeeZeroError();
error Pool_DepositFeeChargeFailedError();
error Pool_WithdrawFeeChargeFailedError();
error Pool_NotEnoughAmountDepositedError();
error Pool_NotEnoughBalanceToDepositError();
error Pool_AssetTransferFailedError();
error Pool_OnlyOneActiveBPError();
error Pool_BPDoesNotExistBPError();
error Pool_ExpiredBPError();
error Pool_Paused();

contract Pool is IPool, Ownable, ReentrancyGuard, ERC4626, IERC1155Receiver {
    using Math for uint64;

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
        uint64 claimableRewardsBP; // Claimable rewards generated from a Booster Pack.
        uint128 totalAmountDeposited; // Total amount deposited.
        uint128 activeBoosterPack; // ID of the active Booster Pack of the User, if there is any.
        uint64 boosterPackActivationBlock; // Block when the Booster Pack of the User was activated, if there is any.
        uint32 nextDepositIdToRemove; // Next Deposit to be removed.
        uint128 rewardsPerToken; // Rewards per token when the user made the first deposit.
        DepositData[] deposits; // Deposits of the User.
    }

    /// @notice Variable to store the deposit asset.
    TheToken private _depositAsset;

    /// @notice Variable to store the base rate of tokens emitted per block.
    uint128 private _baseRateTokensPerBlock;

    /// @notice Variable to store the deposit fee.
    uint128 private _depositFee;

    /// @notice Variable to store the total amount deposited.
    uint128 private _totalAmount;

    /// @notice Variable to store the recipient address that will receive the deposit fees.
    address private _depositFeeRecipient;

    /// @notice Variable to store the rewards per token.
    uint128 private _rewardsPerToken;

    /// @notice Variable to store the last block when the rewardsPerToken was updated.
    uint128 private _lastBlockUpdated;

    /// @notice Array to store the Reward Multipliers.
    RewardsMultiplier[] private _rewardsMultipliers;

    /// @notice Array to store the Withdraw Fees.
    WithdrawFee[] private _withdrawFees;

    /// @notice Mapping to store the information from the Users.
    mapping(address => UserData) private _usersData;

    /// @notice Array to store the users with burned BoosterPacks.
    address[] private _usersWithBoosterPacks;

    /// @notice Mapping to store the rewards per token per Booster Pack.
    mapping(address => uint128) private _rewardsPerTokenBoosterPack;

    /// @notice Variable to know if the Pool is paused.
    bool private _paused;

    /// @dev Constant to avoid divisions resulting in 0
    uint128 public constant MULTIPLIER = 1000;

    ITheToken private _token;
    IBoosterPack private _boosterPack;

    // *** Modifiers ***

    /**
     * @dev Modifier that checks if a RewardsMultiplier exists
     * @param rewardsMultiplierId_ ID of the RewardsMultiplier
     */
    modifier rewardsMultiplierExists(uint32 rewardsMultiplierId_) {
        if (rewardsMultiplierId_ > _rewardsMultipliers.length) revert Pool_RewardsMultiplierDoesNotExistError();
        _;
    }

    /**
     * @dev Modifier that checks if a WithdrawFee exists
     * @param withdrawFeeId_ ID of the WithdrawFee
     */
    modifier withdrawFeeExists(uint32 withdrawFeeId_) {
        if (withdrawFeeId_ > _withdrawFees.length) revert Pool_WithdrawFeeDoesNotExistError();
        _;
    }

    /**
     * @dev Modifier that checks if a WithdrawFee exists
     */
    modifier whenNotPaused() {
        if (_paused) revert Pool_Paused();
        _;
    }

    constructor(
        address asset_,
        address depositFeeRecipient_,
        uint32 baseRateTokensPerBlock_,
        uint32 depositFee_,
        uint64[] memory rewardsMultiplierBlocks_,
        uint64[] memory rewardsMultipliers_,
        uint64[] memory withdrawFeeBlocks_,
        uint64[] memory withdrawFees_,
        address boosterPacksAddress_
    ) ERC4626(IERC20(asset_)) ERC20("Deposit Pool", "DP") {
        // Check if the length of the parameters it's the same, depending if it's for the RewardMultipliers or the WithdrawFees
        uint32 numberOfRewardMultipliers_ = uint32(rewardsMultiplierBlocks_.length);
        if (numberOfRewardMultipliers_ == 0) revert Pool_RewardMultipliersAmountZeroError();
        if (numberOfRewardMultipliers_ != rewardsMultipliers_.length) {
            revert Pool_InitializeRewardMultipliersParametersFormatError();
        }

        uint32 numberOfWithdrawFees_ = uint32(withdrawFeeBlocks_.length);
        if (numberOfWithdrawFees_ == 0) revert Pool_WithdrawFeesAmountZeroError();
        if (numberOfWithdrawFees_ != withdrawFees_.length) {
            revert Pool_InitializeWithdrawFeesParametersFormatError();
        }

        // Set the value of the _depositAsset variable.
        _depositAsset = TheToken(asset_);

        // Set the value of the _boosterPack variable.
        _boosterPack = IBoosterPack(boosterPacksAddress_);

        // Set the value of the _depositFeeRecipient variable.
        _depositFeeRecipient = depositFeeRecipient_;

        // Set the value of the _baseRateTokensPerBlock variable.
        _baseRateTokensPerBlock = baseRateTokensPerBlock_;

        // Set the value of the _depositFeevariable variable.
        _depositFee = depositFee_;

        // Initialize the _rewardsMultiplier array.
        _initializeRewardsMultipliers(rewardsMultiplierBlocks_, rewardsMultipliers_);

        // Initialize the _withdrawFees array.
        _initializeWithdrawFees(withdrawFeeBlocks_, withdrawFees_);
    }

    // *** Functions ***

    // IERC135 Functions
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == type(IPool).interfaceId;
    }

    // IERC1155Receiver Functions
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) { 
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) { 
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    // *** External Functions ***

    /**
     * @dev Updates the _baseRateTokensPerBlock variable.
     * @param newBaseRateTokensPerBlock_ The new value.
     */
    function updateBaseRateTokensPerBlock(uint32 newBaseRateTokensPerBlock_) external onlyOwner whenNotPaused {
        // Update the baseRateTokensPerBlock variable.
        _baseRateTokensPerBlock = newBaseRateTokensPerBlock_;
    }

    /**
     * @dev Updates the _depositFee variable.
     * @param newDepositFee_ The new value.
     */
    function updateDepositFee(uint32 newDepositFee_) external onlyOwner whenNotPaused {
        // Update the depositFee variable.
        _depositFee = newDepositFee_;
    }

    /**
     * @dev Adds a new rewards multiplier.
     * @param blockNumber_ The block number value.
     * @param multiplier_ The multiplier value.
     */
    function addRewardsMultiplier(uint32 blockNumber_, uint32 multiplier_) external onlyOwner whenNotPaused {
        // Check if the parameters are correct
        if (blockNumber_ == 0) revert Pool_BlockNumberZeroError();
        if (multiplier_ == 0) revert Pool_RewardsMultiplierZeroError();

        // Add the rewards multiplier.
        _rewardsMultipliers.push(RewardsMultiplier(blockNumber_, multiplier_));
    }

    /**
     * @dev Updates the rewards multiplier.
     * @param rewardsMultiplierId_ The ID of the rewardsMultiplier.
     * @param blockNumber_ The block number value.
     * @param multiplier_ The multiplier value.
     */
    function updateRewardsMultiplier(uint32 rewardsMultiplierId_, uint32 blockNumber_, uint32 multiplier_)
        external
        onlyOwner
        whenNotPaused
        rewardsMultiplierExists(rewardsMultiplierId_)
    {
        // Check if the parameters are correct
        if (blockNumber_ == 0) revert Pool_BlockNumberZeroError();
        if (multiplier_ == 0) revert Pool_RewardsMultiplierZeroError();

        // Update the rewards multiplier.
        _rewardsMultipliers[rewardsMultiplierId_].blockNumber = blockNumber_;
        _rewardsMultipliers[rewardsMultiplierId_].multiplier = multiplier_;
    }

    /**
     * @dev Removes the rewards multiplier.
     * @param rewardsMultiplierId_ The ID of the rewardsMultiplier.
     */
    function removeRewardsMultiplier(uint32 rewardsMultiplierId_)
        external
        onlyOwner
        whenNotPaused
        rewardsMultiplierExists(rewardsMultiplierId_)
    {
        // Remove the rewards multiplier.
        delete _rewardsMultipliers[rewardsMultiplierId_]; 
    }

    /**
     * @dev Adds a new withdraw fee.
     * @param blockNumber_ The block number value.
     * @param fee_ The fee value.
     */
    function addWithdrawFee(uint32 blockNumber_, uint32 fee_) external onlyOwner whenNotPaused {
        // Check if the parameters are correct
        if (blockNumber_ == 0) revert Pool_BlockNumberZeroError();
        if (fee_ == 0) revert Pool_WithdrawFeeZeroError();

        // Add the withdraw fee.
        _withdrawFees.push(WithdrawFee(blockNumber_, fee_));
    }

    /**
     * @dev Updates the withdraw fee.
     * @param withdrawFeeId_ The ID of the withdrawFee.
     * @param blockNumber_ The block number value.
     * @param fee_ The fee value.
     */
    function updateWithdrawFee(uint32 withdrawFeeId_, uint32 blockNumber_, uint32 fee_)
        external
        onlyOwner
        whenNotPaused
        withdrawFeeExists(withdrawFeeId_)
    {
        // Check if the parameters are correct
        if (blockNumber_ == 0) revert Pool_BlockNumberZeroError();
        if (fee_ == 0) revert Pool_WithdrawFeeZeroError();

        // Update the withdraw fee.
        _withdrawFees[withdrawFeeId_].blockNumber = blockNumber_;
        _withdrawFees[withdrawFeeId_].fee = fee_;
    }

    /**
     * @dev Removes the withdraw fee.
     * @param withdrawFeeId_ The ID of the withdrawFee.
     */
    function removeWithdrawFee(uint32 withdrawFeeId_)
        external
        onlyOwner
        whenNotPaused
        withdrawFeeExists(withdrawFeeId_)
    {
        // Remove the withdraw fee.
        delete _withdrawFees[withdrawFeeId_]; 
    }

    /**
     * @dev Adds a new deposit.
     * @param amount_ Amount to be deposited.
     */
    function deposit(uint128 amount_) external whenNotPaused nonReentrant {
        // Compute BoosterPack rewards if there is any.
        _calcBPRewards();
        
        // Update the rewards per token.
        _updateRewardsPerToken();

        // Get the total deposit taking into account the deposit fee.
        uint32 totalFee_ = uint32(_depositFee * MULTIPLIER / 100);
        uint32 depositedAmount_ = uint32(amount_ - ((amount_ * totalFee_) / MULTIPLIER));
        if (_depositAsset.balanceOf(msg.sender) < depositedAmount_) revert Pool_NotEnoughBalanceToDepositError();

        // Transfer the deposit fee into the recipient address.
        bool success_ = _depositAsset.transferFrom(msg.sender, _depositFeeRecipient, amount_ - depositedAmount_);
        if (!success_) revert Pool_DepositFeeChargeFailedError();

        // Add the deposit.
        _usersData[msg.sender].deposits.push(DepositData(uint64(block.number), depositedAmount_));

        // Transfer the assets into the Pool.
        success_ = _depositAsset.transferFrom(msg.sender, address(this), depositedAmount_);
        if (!success_) revert Pool_AssetTransferFailedError();

        // Update the totalAmountDeposited by the User.
        _usersData[msg.sender].totalAmountDeposited += depositedAmount_;

        // Update the total deposited amount.
        _totalAmount += depositedAmount_;

        // Update the next Deposit to be removed if it's the first Deposit of the User and the rewardsPerToken for the user.
        if (_usersData[msg.sender].deposits.length == 1) {
            _usersData[msg.sender].nextDepositIdToRemove = 0;
            _usersData[msg.sender].rewardsPerToken = _rewardsPerToken;
        }
    }

    /**
     * @dev Withdraw a deposit.
     * @param amount_ Amount to be withdrawed.
     */
    function withdraw(uint128 amount_) external nonReentrant {
        // If the Pool is paused we don't update anything regarding rewards.
        if (!_paused) {
            // Compute BoosterPack rewards if there is any.
            _calcBPRewards();

            // Update the rewards per token.
            _updateRewardsPerToken();
        }

        // Check if the user has deposited enough amount as the requested to withdraw.
        if (_usersData[msg.sender].totalAmountDeposited < amount_) revert Pool_NotEnoughAmountDepositedError();

        // Check user's deposits in order to compute the amount to withdraw.
        uint128 withdrawAmount_;
        uint128 totalFee_;
        for (uint32 i = _usersData[msg.sender].nextDepositIdToRemove; i < _usersData[msg.sender].deposits.length; i++) {
            // If we haven't reach the total amount requested, we continue.
            if (withdrawAmount_ >= amount_) {
                break;
            }

            // Remaining amount to be obtained from the deposits.
            uint128 amountRem_ = amount_ - withdrawAmount_;
            uint128 depositAmount_ = _usersData[msg.sender].deposits[i].amount;

            // Compute the withdraw fee and the resulting amount of the deposit.
            uint64 withdrawFee_ =
                uint64(_calcWithdrawFeePerBlock(_usersData[msg.sender].deposits[i].blockNumber) * MULTIPLIER / 100);
            uint128 depositAmountFeed_ = uint128(depositAmount_ - depositAmount_ * withdrawFee_ / MULTIPLIER);

            // Check if the deposit can manage the full remaining amount of the withdrawal.
            if (depositAmountFeed_ > amountRem_) {
                // Update user information regarding the deposit and the total amount deposited.
                _usersData[msg.sender].deposits[i].amount -= amountRem_;
                _usersData[msg.sender].totalAmountDeposited -= amountRem_;

                // Update the withdrawAmount and the totalFee.
                withdrawAmount_ += amountRem_;
                totalFee_ += uint128((amountRem_ * withdrawFee_) / MULTIPLIER);

                continue;
            }

            // Update user information regarding the deposit and the total amount deposited.
            _usersData[msg.sender].deposits[i].amount = 0;
            _usersData[msg.sender].totalAmountDeposited -= depositAmount_;

            // Update the total deposited amount.
            _totalAmount -= depositAmount_;

            // Update the withdrawAmount and the totalFee.
            withdrawAmount_ += depositAmountFeed_;
            totalFee_ += uint128((depositAmount_ * withdrawFee_) / MULTIPLIER);

            // This deposit it's no longer available. Update the nextDeposit to be removed.
            _usersData[msg.sender].nextDepositIdToRemove = i == _usersData[msg.sender].deposits.length - 1 ? i : i + 1;
        }

        _depositAsset.approve(address(this), withdrawAmount_ + totalFee_);
        // Transfer the assets to the user.
        bool success_ = _depositAsset.transferFrom(address(this), msg.sender, withdrawAmount_);
        if (!success_) revert Pool_AssetTransferFailedError();

        // Transfer the withdraw fee into the recipient address.
        success_ = _depositAsset.transferFrom(address(this), _depositFeeRecipient, totalFee_);
        if (!success_) revert Pool_WithdrawFeeChargeFailedError();
    }

    /**
     * @dev Claim rewards for a specific user.
     * @param user_ Address from the user.
     */
    function claimRewards(address user_) external nonReentrant {
        // If the Pool is paused we don't update anything regarding rewards.        
        if (!_paused) {
            // Check if the caller has an expired BoosterPack.
            _checkBPExpired(user_);

            // Update the rewards per token.
            _updateRewardsPerToken();
        }

        // Check user's deposits in order to compute the total rewards accumulated.
        uint64 userTotalRewards_ = uint64((_rewardsPerToken - _usersData[user_].rewardsPerToken) * _usersData[user_].totalAmountDeposited / MULTIPLIER);
        uint64 userClaimableRewards_ = uint64(userTotalRewards_ - _usersData[user_].accumRewards);

        // Update the user's accumulated rewards.
        _usersData[user_].accumRewards = userTotalRewards_;

        // Mint the tokens to the user.
        _depositAsset.mint(user_, userClaimableRewards_);
        _depositAsset.mint(user_, _usersData[user_].claimableRewardsBP);

        // Update the user's claimable rewards BP.
        _usersData[user_].claimableRewardsBP = 0;
    }

    /**
     * @dev Burn a Booster Pack amount.
     * @param id_ ID of the booster pack.
     */
    function burnBP(uint32 id_) external whenNotPaused nonReentrant {
        // Check if the caller has an expired BoosterPack.
        _checkBPExpired(msg.sender);

        // Update the rewards per token.
        _updateRewardsPerToken();
        
        // Check if the sender has already an active BoosterPack.
        if (_usersData[msg.sender].activeBoosterPack != 0) revert Pool_OnlyOneActiveBPError();

        // Check expiration date.
        uint64 expirationDate = _boosterPack.getExpirationDate(id_);
        if (expirationDate == 0) revert Pool_BPDoesNotExistBPError();
        if (expirationDate < block.number) revert Pool_ExpiredBPError();

        // Transfer the BoosterPack to the Pool and burn it.
        _boosterPack.safeTransferFrom(msg.sender, address(this), id_, 1, "");
        _boosterPack.burn(id_, 1);

        // Set up the active Booster Pack to the user.
        _usersData[msg.sender].activeBoosterPack = id_; 
        _usersData[msg.sender].boosterPackActivationBlock = uint64(block.number);

        _usersWithBoosterPacks.push(msg.sender);
    }

    /**
     * @dev Pauses the Pool.
     */
    function pause() external onlyOwner {
        // Pause the Pool.
        _paused = true;

        // Compute BoosterPack rewards if there is any.
        _calcBPRewards();

        // Update the rewards per token.
        _updateRewardsPerToken();
    }

    /**
     * @dev Unpauses the Pool.
     */
    function unpause() external onlyOwner {
        // Unpause the Pool.
        _paused = false;
    }

    // *** Getters ***

    /**
     * @dev Getter for the _baseRateTokensPerBlock variable.
     */
    function getBaseRateTokensPerBlock() external view onlyOwner returns (uint128) {
        return _baseRateTokensPerBlock;
    }

    /**
     * @dev Getter for the _depositFee variable.
     */
    function getDepositFee() external view onlyOwner returns (uint128) {
        return _depositFee;
    }

    /**
     * @dev Getter for the _depositFeeRecipient variable.
     */
    function getDepositFeeRecipient() external view onlyOwner returns (address) {
        return _depositFeeRecipient;
    }

    /**
     * @dev Getter for the _rewardsPerToken variable.
     */
    function getRewardsPerToken() external view onlyOwner returns (uint128) {
        return _rewardsPerToken;
    }

    /**
     * @dev Getter for the _lastBlockUpdated variable.
     */
    function getLastBlockUpdated() external view onlyOwner returns (uint128) {
        return _lastBlockUpdated;
    }

    /**
     * @dev Getter for the _paused variable.
     */
    function getPaused() external view onlyOwner returns (bool) {
        return _paused;
    }

    /**
     * @dev Getter for the _rewardsMultiplier blockNumber.
     * @param rewardsMultiplierId_ ID of the RewardsMultiplier.
     */
    function getRewardsMultiplierBlockNumber(uint32 rewardsMultiplierId_) external view onlyOwner returns (uint64) {
        return _rewardsMultipliers[rewardsMultiplierId_].blockNumber;
    }

    /**
     * @dev Getter for the _rewardsMultiplier multiplier.
     * @param rewardsMultiplierId_ ID of the RewardsMultiplier.
     */
    function getRewardsMultiplier(uint32 rewardsMultiplierId_) external view onlyOwner returns (uint64) {
        return _rewardsMultipliers[rewardsMultiplierId_].multiplier;
    }

    /**
     * @dev Getter for the _withdrawFees blockNumber.
     * @param withdrawFeeId_ ID of the WithdrawFee.
     */
    function getWithdrawFeeBlockNumber(uint32 withdrawFeeId_) external view onlyOwner returns (uint64) {
        return _withdrawFees[withdrawFeeId_].blockNumber;
    }

    /**
     * @dev Getter for the _rewardsPerToken fee.
     * @param withdrawFeeId_ ID of the WithdrawFee.
     */
    function getWithdrawFee(uint32 withdrawFeeId_) external view onlyOwner returns (uint64) {
        return _withdrawFees[withdrawFeeId_].fee;
    }

    /**
     * @dev Getter for the user accumRewards.
     * @param user_ Address of the user.
     */
    function getUserAccumRewards(address user_) external view onlyOwner returns (uint64) {
        return _usersData[user_].accumRewards;
    }

    /**
     * @dev Getter for the user getUserAccumRewardsBP.
     * @param user_ Address of the user.
     */
    function getUserAccumRewardsBP(address user_) external view onlyOwner returns (uint64) {
        return _usersData[user_].accumRewardsBP;
    }

    /**
     * @dev Getter for the user claimableRewardsBP.
     * @param user_ Address of the user.
     */
    function getUserClaimableRewardsBP(address user_) external view onlyOwner returns (uint64) {
        return _usersData[user_].claimableRewardsBP;
    }

    /**
     * @dev Getter for the user totalAmountDeposited.
     * @param user_ Address of the user.
     */
    function getUserTotalAmountDeposited(address user_) external view onlyOwner returns (uint128) {
        return _usersData[user_].totalAmountDeposited;
    }

    /**
     * @dev Getter for the user activeBoosterPack.
     * @param user_ Address of the user.
     */
    function getUserActiveBoosterPack(address user_) external view onlyOwner returns (uint128) {
        return _usersData[user_].activeBoosterPack;
    }

    /**
     * @dev Getter for the _usersWithBoosterPacks array.
     * @param id_ Index of the array.
     */
    function getUsersWithBoosterPacks(uint256 id_) external view onlyOwner returns (address) {
        return _usersWithBoosterPacks[id_];
    }

    /**
     * @dev Getter for the user _rewardsPerTokenBoosterPack.
     * @param user_ Address of the user.
     */
    function getRewardsPerTokenBoosterPack(address user_) external view onlyOwner returns (uint128) {
        return _rewardsPerTokenBoosterPack[user_];
    }

    /**
     * @dev Getter for the user nextDepositIdToRemove.
     * @param user_ Address of the user.
     */
    function getUserNextDepositIdToRemove(address user_) external view onlyOwner returns (uint32) {
        return _usersData[user_].nextDepositIdToRemove;
    }

    /**
     * @dev Getter for the blockNumber of a specified deposit from a user.
     * @param user_ Address of the user.
     * @param depositId_ ID of the deposit.
     */
    function getUserDepositBlockNumber(address user_, uint32 depositId_) external view onlyOwner returns (uint64) {
        return _usersData[user_].deposits[depositId_].blockNumber;
    }

    /**
     * @dev Getter for the amount of a specified deposit from a user.
     * @param user_ Address of the user.
     * @param depositId_ ID of the deposit.
     */
    function getUserDepositAmount(address user_, uint32 depositId_) external view onlyOwner returns (uint128) {
        return _usersData[user_].deposits[depositId_].amount;
    }

    // *** Internal Functions ***

    /**
     * @dev Initializes the rewardsMultiplier array with the given parameters.
     * @param blockNumbers_ Block numbers of the rewardsMultipliers.
     * @param multipliers_ Multipliers of the rewardsMultipliers.
     */
    function _initializeRewardsMultipliers(uint64[] memory blockNumbers_, uint64[] memory multipliers_) internal {
        // Initialize the rewardsMultiplier array using the parameters.
        for (uint256 i = 0; i < blockNumbers_.length; i++) {
            _rewardsMultipliers.push(RewardsMultiplier(blockNumbers_[i], multipliers_[i]));
        }
    }

    /**
     * @dev Initializes the withdrawFees array with the given parameters.
     * @param blockNumbers_ Block numbers of the withdrawFee.
     * @param fees_ Fees of the withdrawFee.
     */
    function _initializeWithdrawFees(uint64[] memory blockNumbers_, uint64[] memory fees_) internal {
        // Initialize the withdrawFee array with the parameters.
        for (uint256 i = 0; i < blockNumbers_.length; i++) {
            _withdrawFees.push(WithdrawFee(blockNumbers_[i], fees_[i]));
        }
    }

    /**
     * @dev Returns the withdraw fee corresponding to the blockNumber.
     * @param blockNumber_ Block number of the deposit.
     */
    function _calcWithdrawFeePerBlock(uint64 blockNumber_) internal view returns (uint64) {
        for (uint256 i = 0; i < _withdrawFees.length; i++) {
            if (blockNumber_ < _withdrawFees[i].blockNumber) {
                return _withdrawFees[i].fee;
            }
        }
        return 0;
    }

    /**
     * @dev Updates the _rewardsPerToken variable.
     */
    function _updateRewardsPerToken() internal {
        uint128 currentBlock_ = uint128(block.number);

        if (_totalAmount != 0) {
            // Check current interval's rewards multiplier
            for (uint256 i = 0; i < _rewardsMultipliers.length; i++) {
                RewardsMultiplier memory rewardMultiplier_;
                rewardMultiplier_ = _rewardsMultipliers[i];

                // If the current block fit's into the rewards multiplier period we use it's multiplier and break.
                if (currentBlock_ <= rewardMultiplier_.blockNumber) {
                    _rewardsPerToken += (_baseRateTokensPerBlock * rewardMultiplier_.multiplier)
                        * (currentBlock_ - _lastBlockUpdated) * MULTIPLIER / _totalAmount;
                    _lastBlockUpdated = currentBlock_;
                    break;
                }
                // If the _lastBlockUpdated block fit's into the rewards multiplier period we use it's multiplier and continue until we reach the currentBlock.
                else if (_lastBlockUpdated <= rewardMultiplier_.blockNumber) {
                    _rewardsPerToken += (_baseRateTokensPerBlock * rewardMultiplier_.multiplier)
                        * (rewardMultiplier_.blockNumber - _lastBlockUpdated) * MULTIPLIER / _totalAmount;
                    _lastBlockUpdated = rewardMultiplier_.blockNumber + 1;
                }
            }
        }

        _lastBlockUpdated = currentBlock_;
    }

    /**
     * @dev Checks if an active user's BoosterPack has already expired and updates it.
     * @param user_ User to check from the BoosterPack status.
     */
    function _checkBPExpired(address user_) internal {
        // Check if the user has an active BoosterPack.
        uint128 userBP = _usersData[user_].activeBoosterPack;
        if (userBP != 0) {
            // Compute the pending rewards accrued from this BoosterPack. 
            _calcBPRewardsUser(user_);
            
            // Check if the BoosterPack period has ended.
            uint64 boosterPackDuration_ = _boosterPack.getDuration(uint32(userBP));
            uint64 boosterPackActivationBlock_ = _usersData[user_].boosterPackActivationBlock;
            if ((boosterPackDuration_ + boosterPackActivationBlock_) < block.number) {
                // Set the user's active BoosterPack.
                _usersData[user_].activeBoosterPack = 0;
                _usersData[user_].boosterPackActivationBlock = 0;

                // Delete the information from the user on the _usersWithBoosterPacks array.
                for (uint256 i = 0; i < _usersWithBoosterPacks.length; i++) { 
                    if (_usersWithBoosterPacks[i] == user_) {
                        delete _usersWithBoosterPacks[i];
                        break;
                    }
                }
            }
        }
    }

    /**
     * @dev Checks if there is any BoosterPack that has already expired and updates the rewards.
     */
    function _calcBPRewards() internal {
        // Check every stored burned Booster Pack
        for (uint256 i = 0; i < _usersWithBoosterPacks.length; i++) {
            address user_ = _usersWithBoosterPacks[i];
            uint128 userBP = _usersData[user_].activeBoosterPack;

            // Compute the pending rewards accrued from this BoosterPack. 
            _calcBPRewardsUser(user_);
            
            // Check if the BoosterPack period has ended.
            uint64 boosterPackDuration_ = _boosterPack.getDuration(uint32(userBP));
            uint64 boosterPackActivationBlock_ = _usersData[user_].boosterPackActivationBlock;
            if ((boosterPackDuration_ + boosterPackActivationBlock_) < block.number) {
                // Set the user's active BoosterPack.
                _usersData[user_].activeBoosterPack = 0;
                _usersData[user_].boosterPackActivationBlock = 0;
            }
        }
    }

    /**
     * @dev Computes the user's rewards accrued from the BoosterPack.
     * @param user_ User to compute rewards from the BoosterPack.
     */
    function _calcBPRewardsUser(address user_) internal {
        // Get BoosterPack data.
        uint32 boosterPackId_ = uint32(_usersData[user_].activeBoosterPack);
        uint64 boosterPackDuration_ = _boosterPack.getDuration(boosterPackId_);
        uint32 boosterPackMultiplier_ = _boosterPack.getMultiplier(boosterPackId_);
        uint64 boosterPackActivationBlock_ = _usersData[user_].boosterPackActivationBlock;

        _updateRewardsPerTokenBP(user_, boosterPackActivationBlock_, boosterPackDuration_);

        // Compute the user's rewards accrued during the period when the BoosterPack was active.
        uint64 userTotalRewardsBP_ = uint64((_rewardsPerTokenBoosterPack[user_] - _usersData[msg.sender].rewardsPerToken) * _usersData[user_].totalAmountDeposited / MULTIPLIER);
        uint64 userClaimableRewardsBP_ = uint64((userTotalRewardsBP_ * boosterPackMultiplier_)- _usersData[user_].claimableRewardsBP);

        // Update the accumulated rewards from BoosterPacks of the user.
        _usersData[user_].claimableRewardsBP += userClaimableRewardsBP_;
        _usersData[user_].accumRewardsBP += userClaimableRewardsBP_;
    }

    /**
     * @dev Updates the _rewardsPerTokenBoosterPack mapping.
     * @param user_ User to update the _rewardsPerTokenBoosterPack.
     * @param boosterPackActivationBlock_ Activation block of the BoosterPack.
     * @param boosterPackDuration_ Duration of the BoosterPack.
     */
    function _updateRewardsPerTokenBP(address user_, uint64 boosterPackActivationBlock_, uint64 boosterPackDuration_) internal {
        uint64 currentBlock_ = uint64(block.number);
        uint64 boosterPackBlock_ = uint64(currentBlock_.min(boosterPackActivationBlock_ + boosterPackDuration_));
        uint128 _lastBlockUpdatedBP = _lastBlockUpdated;

        if (_totalAmount != 0) {
            // Check current interval's rewards multiplier
            for (uint256 i = 0; i < _rewardsMultipliers.length; i++) {
                RewardsMultiplier memory rewardMultiplier_;
                rewardMultiplier_ = _rewardsMultipliers[i];

                // If the current block fit's into the rewards multiplier period we use it's multiplier and break.
                if (boosterPackBlock_ <= rewardMultiplier_.blockNumber) {
                    _rewardsPerTokenBoosterPack[user_] += (_baseRateTokensPerBlock * rewardMultiplier_.multiplier)
                        * (boosterPackBlock_ - _lastBlockUpdatedBP) * MULTIPLIER / _totalAmount;
                    break;
                }
                // If the _lastBlockUpdatedBP block fit's into the rewards multiplier period we use it's multiplier and continue until we reach the currentBlock.
                else if (_lastBlockUpdatedBP <= rewardMultiplier_.blockNumber) {
                    _rewardsPerTokenBoosterPack[user_] += (_baseRateTokensPerBlock * rewardMultiplier_.multiplier)
                        * (rewardMultiplier_.blockNumber - _lastBlockUpdatedBP) * MULTIPLIER / _totalAmount;
                    _lastBlockUpdatedBP = rewardMultiplier_.blockNumber + 1;
                }
            }
        }
    }
}
