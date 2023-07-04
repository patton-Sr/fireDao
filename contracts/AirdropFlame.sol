
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/"
import "./interface/IFireSoul.sol";
import "./interface/IFireSeed.sol";

contract airdropFlame is Ownable{
    struct airdrops{
        address user;
        bool isNotBlackList;
    }
    ERC20 flame;
    address public controlStatus;
    bool public Status;
    address public FireSoulAddress;
    address public FireSeedAddress;
    airdrops[] public airdropList;
    mapping(address => bool) public airdropUser;
    mapping(address => bool) public blackList;
    constructor () {
    }

    //onlyOwner
    function getUserListLength() public view returns(uint256) {
        return airdropList.length;
    }
    function addAirdropUser(address[] memory _user) public onlyOwner {
        for(uint256 i = 0; i < _user.length; i ++) {
            airdropUser[_user[i]] = true;
            airdrops memory userInfo= airdrops({ user:_user[i], isNotBlackList:false});
            airdropList.push(userInfo);
        }
    }
    function reAddAirdropUser(address[] memory _user) public onlyOwner{
        for(uint256 i = 0 ; i< _user.length ; i ++) {
        require(!airdropUser[_user[i]],'you have added airdrop list');
        require(!blackList[_user[i]],'you can not add blackList user');
            airdropUser[_user[i]] = true;
            airdrops memory userInfo= airdrops({ user:_user[i], isNotBlackList:false});
            airdropList.push(userInfo);
        }
    }
    function removeAddr(address _addr) internal {
        for(uint256 i = 0 ; i< getUserListLength(); i++) {
            if(airdropList[i].user == _addr) {
                airdropList[i] = airdropList[airdropList.length - 1];
                airdropList.pop();
            }
        }
    }

    function removeAirdropUser(address[] memory _user) public onlyOwner {
        for(uint256 i = 0 ; i < _user.length ; i ++) {
            airdropUser[_user[i]] = false;
        }
    }
    function setFireSoulAddress(address _FireSoulAddress) public onlyOwner{
        FireSoulAddress = _FireSoulAddress;
    }
    function setflameAddress(ERC20 _flame) public onlyOwner{
        flame = _flame;
    }
    function setControlStatusAddress(address controlAddress) public onlyOwner {
        controlStatus =controlAddress;
    }
    function setStatus() external {
        require(msg.sender == controlStatus, "is not control contract");
        Status =!Status;
    }
    function setBlackList(address user) public onlyOwner{
        blackList[user] = true;
    }
    //main
    function checkBalanceOfThis() public view returns(uint256) {
        return IERC20(flame).balanceOf(address(this));
    }

    function receiveAirdrop() public {
        require(!Status, "the status is false");
        require(!blackList[msg.sender] ,"you are blackList User");
        require(airdropUser[msg.sender], "you are not airdrop User");
        require(IERC20(flame).balanceOf(address(this)) > 0, "amount is not enough");
        if(IFireSoul(FireSoulAddress).checkFID(msg.sender)){
        flame.transfer(IFireSeed(FireSeedAddress).upclass(msg.sender),4000*10**18);
        flame.transfer(IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender)),2400*10**18);
        flame.transfer(IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender))),1600*10**18);
        flame.transfer(msg.sender,40000*10**18);
        }else{
        flame.transfer(msg.sender,4000*10**18);
        flame.transfer(IFireSeed(FireSeedAddress).upclass(msg.sender),400*10**18);
        flame.transfer(IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender)),240*10**18);
        flame.transfer(IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(IFireSeed(FireSeedAddress).upclass(msg.sender))),160*10**18);
        }
    }
}
