//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFireSoul {
	function checkIsNotFidUser(address user) external view returns(bool);
    function getSoulAccount(address _user) external view returns(address);
    function getFid(address _user) external view returns(uint256);
}