// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ISBT.sol";

/**
 * @title IERC4671
 * @dev Interface implementation for {https://eips.ethereum.org/EIPS/eip-4671}
 */
interface IUserNFT is ISBT {

  event MintUserNFT(address member);

  function mint(address member) external;

}
