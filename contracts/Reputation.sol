// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IFireSoul.sol";

contract Reputation is Ownable
{ 
    bool initStatus;
    uint256[] public coefficient;
    address[] public sbt;
    address public fireSoul;
    constructor()  {
    }

    function initializer() public {
        require(!initStatus, "inited");
        sbt.push(address(0x43387c942d7dd16aEa3134c9c9Dc7687C41005B4));
        sbt.push(address(0xb3CDC058F8910D95dADC1456F898E8a8458C053d));
        coefficient.push(1);
        coefficient.push(2);
        initStatus = true;
    }
    //onlyOwner
    function addSBTAddress(address _sbt, uint256 _coefficient) public onlyOwner {
        sbt.push(_sbt);
        coefficient.push(_coefficient);
    }
    function setSBTAddress(uint256 num, address _sbt) public onlyOwner {
        require(num < sbt.length, "num is bigger than length");
        sbt[num] = _sbt;
    }
    function setCoefficient(uint256 num, uint256 _coefficient) public onlyOwner {
        require(num < coefficient.length, "num is bigger than length");
        coefficient[num] = _coefficient;
    }

    function setFireSoulAddress(address _fireSoul) public onlyOwner {
        fireSoul = _fireSoul;
    }
    //main
    function checkReputation(address _user) external view returns(uint256) {
        uint256 ReputationPoint;
        for(uint i = 0 ; i < sbt.length; i ++) {
            ReputationPoint =  IERC20(sbt[i]).balanceOf(IFireSoul(fireSoul).getSoulAccount(_user))*coefficient[i] +ReputationPoint; 

        }
        return ReputationPoint;
    }
    function getSbtLength() public view returns(uint256) {
        return sbt.length;
    }

}
