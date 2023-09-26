// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/INutritionistNFT.sol";
import {SBT} from "./SBT.sol";

contract NutritionistNFT is INutritionistNFT, SBT {
    constructor(string memory name, string memory symbol) SBT(name, symbol) {}

    // FUNCTIONS
    function mint(address nutritionist) external override {
        _mintUsingAutomaticTokenId(nutritionist);

        emit MintNutritionistNFT(nutritionist);
    }
}
