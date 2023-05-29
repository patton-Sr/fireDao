pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/TransferHelper.sol";

contract LpLockMining is Ownable {
    
    uint256 immutable public ONE_MONTH = 259200;
    uint256 immutable public ONE_BLOCK = 4;
    uint256 public FLM_AMOUNT;
    uint256 public REWARD_CYCLE;
    address public flm;
    mapping(uint256 => uint256) public Weights;
    constructor(address _flm) {
        flm = _flm;
        Weights[0] = 1;
        Weights[1] = 2;
        Weights[3] = 3;
        Weights[6] = 4;
        Weights[12] = 5;
        Weights[24] = 6;
        Weights[36] = 7;

    }
    function setFlmAddress(address _flm) public onlyOwner {
        flm = _flm;
    }
    function setREWARD_CYCLE(uint256 _several) public onlyOwner {
        FLM_AMOUNT = IERC20(flm).balanceOf(address(this)); 
        REWARD_CYCLE =  _several * ONE_MONTH;
    }

    function lockLp(uint256 _several) public {
        require(
                _several == 0 ||
                _several == 1 || 
                _several == 3 ||
                _several == 6 ||
                _several == 12||
                _several == 24||
                _several == 36 ,
                "Please enter the correct lock-up month");
                
    }
    function setWeights(uint256 _month,uint256 _weight) public onlyOwner {
        Weights[_month] = _weight;
    }
    function backToken(address _token) public onlyOwner {
        TransferHelper.safeTransfer(_token, msg.sender, IERC20(_token).balanceOf(address(this)));
    }
}