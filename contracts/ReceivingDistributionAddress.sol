pragma solidity =0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
contract ReceivingDistributionAddress is Ownable{
    uint256 public baseRate;
    mapping(address => uint256) public userDistributeRate;
    mapping(address => bool) public powerContracts;
    constructor(){

    }
    function setPowerContracts(address _contracts, bool _set) public onlyOwner{
        powerContracts[_contracts] = _set;
    }
    function setUserDistributeRate(address _user, uint256 _rate) public onlyOwner {
        userDistributeRate[_user] = _rate;
    }
    function distribute() external {

    }

}