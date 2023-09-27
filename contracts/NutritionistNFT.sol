// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/INutritionistNFT.sol";
import {SBT} from "./SBT.sol";

contract NutritionistNFT is INutritionistNFT, SBT {
    address public owner;

    constructor(
        string memory name,
        string memory symbol,
        address _owner
    ) SBT(name, symbol) {
        owner = _owner;
    }

    // FUNCTIONS
    function mint(address nutritionist) external override {
        require(msg.sender == owner, "caller not owner");
        _mintUsingAutomaticTokenId(nutritionist);

        emit MintNutritionistNFT(nutritionist);
    }

    function burn(address nutritionist, uint256 _tokenId) external override {
        require(msg.sender == owner, "caller not owner");
        _burn(nutritionist, _tokenId);

        emit BurnNutritionistNFT(nutritionist, _tokenId);
    }
}
