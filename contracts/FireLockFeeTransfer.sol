// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
contract FireLockFeeTransfer is Ownable{
    uint256 public fee;
    address public setAddr;
    constructor(address _setAddr) {
        fee = 80000000000000000;
        setAddr = _setAddr;
    }

function setFee(uint _fee) public onlyOwner{
    fee = _fee;
}
function setAddress(address _addr) public onlyOwner{
    setAddr = _addr;
}
function getFee() external view returns(uint) {
    return fee;
}

function getAddress() external view returns(address) {
    return setAddr;
}
}