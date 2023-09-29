// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ModicumContract {
  function runModuleWithDefaultMediators(string calldata name, string calldata params) external payable returns (uint256);
}