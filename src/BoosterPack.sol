// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/token/ERC1155/ERC1155.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";

/// Errors
error BoosterPack_AddressNotAllowedToMintError();
error BoosterPack_AddressNotAllowedToBurnError();

contract BoosterPack is ERC1155, Ownable {
    /// @notice ERC1155.
    string baseURI;

    /// @notice Struct to store the information about the Attributed of the Booster Pack.
    struct Attributes {
        uint64 duration; // Duration of the Booster Pack.
        uint64 expirationDate; // Expiration date of the Booster Pack.
        uint32 multiplier; // Rewards multiplier of the Booster Pack.
    }

    /// @notice Variable to store the different Booster Packs.
    mapping(uint32 => Attributes) boosterPack;

    ///@notice Mapping to store the whitelisted addresses that can interact with the Booster Packs.
    mapping(address => bool) private whitelistedAddrBP;

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
    }

    /**
     * @dev Mints a Booster Pack amount.
     * @param to Receiver of the booster pack.
     * @param id ID of the booster pack.
     * @param duration Duration of booster packs.
     * @param expirationDate Expiration date of booster packs.
     * @param multiplier multiplier of booster packs.
     */
    function mintBP(address to, uint256 id, uint64 duration, uint64 expirationDate, uint32 multiplier) external {
        // Check if the address is allowed to mint.
        require(whitelistedAddrBP[msg.sender], "You are not allowed to mint."); // TO-DO Custom Error BoosterPack_AddressNotAllowedToMintError

        // Mint the Booster Pack.
        _mint(to, id, 1, "");

        // Update the boosterPack mapping.
        boosterPack[uint32(id)].duration = duration;
        boosterPack[uint32(id)].expirationDate = expirationDate;
        boosterPack[uint32(id)].multiplier = multiplier;
    }

    /**
     * @dev Burns a Booster Pack.
     * @param id ID of the booster pack.
     */
    function burnBP(uint256 id) external {
        // Check if the address is allowed to burn.
        require(whitelistedAddrBP[msg.sender], "You are not allowed to burn."); // TO-DO Custom Error BoosterPack_AddressNotAllowedToBurnError

        // Burns the Booster Pack (No need to check if the user it's the owner because the ERC1155 checks the balance of the caller).
        _burn(msg.sender, id, 1);
    }

    /**
     * @dev Adds a whitelisted address.
     * @param addr Address to be whitelisted.
     */
    function addWhitelistedAddrBP(address addr) external onlyOwner {
        // Add the address to the whitelistedAddrBP mapping.
        whitelistedAddrBP[addr] = true;
    }

    /**
     * @dev Removes a whitelisted address.
     * @param addr Address to be removed from being whitelisted.
     */
    function removeWhitelistedAddrBP(address addr) external onlyOwner {
        // Remove the address to the whitelistedAddrBP mapping.
        whitelistedAddrBP[addr] = false;
    }

    /**
     * @dev Getter for the whitelistedAddrBP mapping.
     * @param addr Address to check if it's whitelisted.
     */
    function getWhitelistedAddrBP(address addr) external view onlyOwner returns (bool) {
        return whitelistedAddrBP[addr];
    }
}
