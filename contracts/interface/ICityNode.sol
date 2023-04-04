// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IcityNode{
  function getIsCityNode(address _account , uint256 _fee) external payable;
}