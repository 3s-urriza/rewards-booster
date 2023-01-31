// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "src/interfaces/IBoosterPack.sol";

import "@openzeppelin/token/ERC1155/ERC1155.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";

/// Errors
error BoosterPack_AddressNotAllowedToMintError();
error BoosterPack_AddressNotAllowedToBurnError();

contract BoosterPack is ERC1155, IBoosterPack, Ownable {
    /// @notice ERC1155.
    string baseURI;

    /// @notice Struct to store the information about the Attributed of the Booster Pack.
    struct Attributes {
        uint64 duration; // Duration of the Booster Pack.
        uint64 expirationDate; // Expiration date of the Booster Pack.
        uint32 multiplier; // Rewards multiplier of the Booster Pack.
    }

    /// @notice Variable to store the different Booster Packs.
    mapping(uint32 => Attributes) _boosterPacks;

    ///@notice Mapping to store the whitelisted addresses that can interact with the Booster Packs.
    mapping(address => bool) private _whitelistedAddrBP; // TO-DO Add one for minting and another for burning

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI; // Check if needed, setUri onlyOwner
    }

    /**
     * @dev Adds a whitelisted address.
     * @param addr_ Address to be whitelisted.
     */
    function addWhitelistedAddrBP(address addr_) external onlyOwner {
        // Add the address to the _whitelistedAddrBP mapping.
        _whitelistedAddrBP[addr_] = true;
    }

    /**
     * @dev Removes a whitelisted address.
     * @param addr_ Address to be removed from being whitelisted.
     */
    function removeWhitelistedAddrBP(address addr_) external onlyOwner {
        // Remove the address to the _whitelistedAddrBP mapping.
        _whitelistedAddrBP[addr_] = false;
    }

    /**
     * @dev Sets Booster Pack attributes.
     * @param id_ ID of the booster pack.
     * @param duration_ Duration of booster packs.
     * @param expirationDate_ Expiration date of booster packs.
     * @param multiplier_ multiplier of booster packs.
     */
    function setAttributes(uint256 id_, uint64 duration_, uint64 expirationDate_, uint32 multiplier_)
        external
        onlyOwner
    {
        // Change the attributes of the boosterPack.
        _boosterPacks[uint32(id_)].duration = duration_;
        _boosterPacks[uint32(id_)].expirationDate = expirationDate_;
        _boosterPacks[uint32(id_)].multiplier = multiplier_;
    }

    /**
     * @dev Mints a Booster Pack amount.
     * @param to_ Receiver of the booster pack.
     * @param id_ ID of the booster pack.
     * @param amount_ Amount of booster packs to be minted.
     * @param duration_ Duration of booster packs.
     * @param expirationDate_ Expiration date of booster packs.
     * @param multiplier_ multiplier of booster packs.
     */
    function mint(
        address to_,
        uint256 id_,
        uint256 amount_,
        uint64 duration_,
        uint64 expirationDate_,
        uint32 multiplier_
    ) external {
        // Check if the address is allowed to mint.
        if (!_whitelistedAddrBP[msg.sender]) revert BoosterPack_AddressNotAllowedToMintError();

        // Mint the Booster Pack.
        _mint(to_, id_, amount_, "");

        // Update the boosterPack mapping.
        _boosterPacks[uint32(id_)].duration = duration_;
        _boosterPacks[uint32(id_)].expirationDate = expirationDate_;
        _boosterPacks[uint32(id_)].multiplier = multiplier_;
    }

    /**
     * @dev Burns a Booster Pack amount.
     * @param id_ ID of the booster pack.
     * @param amount_ Amount of booster packs to be burned.
     */
    function burn(uint256 id_, uint256 amount_) external {
        // Check if the address is allowed to burn.
        if (!_whitelistedAddrBP[msg.sender]) revert BoosterPack_AddressNotAllowedToBurnError();

        // Burns the Booster Pack (No need to check if the user it's the owner because the ERC1155 checks the balance of the caller).
        _burn(msg.sender, id_, amount_);
    }

    /**
     * @dev Getter for the _whitelistedAddrBP mapping.
     * @param addr_ Address to check if it's whitelisted.
     */
    function getWhitelistedAddrBP(address addr_) external view onlyOwner returns (bool) {
        return _whitelistedAddrBP[addr_];
    }

    /**
     * @dev Getter for the BoosterPack duration.
     * @param id_ ID of the Booster Pack.
     */
    function getDuration(uint32 id_) external view returns (uint64) {
        return _boosterPacks[uint32(id_)].duration;
    }

    /**
     * @dev Getter for the BoosterPack expirationDate.
     * @param id_ ID of the Booster Pack.
     */
    function getExpirationDate(uint32 id_) external view returns (uint64) {
        return _boosterPacks[uint32(id_)].expirationDate;
    }

    /**
     * @dev Getter for the BoosterPack multiplier.
     * @param id_ ID of the Booster Pack.
     */
    function getMultiplier(uint32 id_) external view returns (uint32) {
        return _boosterPacks[uint32(id_)].multiplier;
    }
}
