pragma solidity ^0.8.0;

import "./interface/IUniswapV2Router02.sol";
import "./interface/IUniswapV2Factory.sol";
import './interface/IFireSoul.sol';
import './interface/IUniswapV2Pair.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './lib/TransferHelper.sol';
import './interface/ISbt001.sol';
import './interface/ISbt005.sol';
import './lib/SafeMath.sol';

contract LpLockMining is Ownable {
     using SafeMath for uint256;
    
    struct 
    IUniswapV2Pair public  uniswapV2Pair;
    address public Pool;
    uint256 immutable public ONE_MONTH = 259200;
    uint256 immutable public ONE_BLOCK = 4;
    uint256 public ratioAmount;
    uint256 public FLM_AMOUNT;
    uint256 public REWARD_CYCLE;
    address public flm;
    address public fdt;
    address public fireSoul;
    address public sbt001;
    address public sbt005;
    mapping(uint256 => uint256) public Weights;
    constructor(address _fireSoul,address _fdt,address _flm,address _sbt001, address _sbt005) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x2863984c246287aeB392b11637b234547f5F1E70);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .getPair(_fdt, _uniswapV2Router.WETH());
        uniswapV2Pair = IUniswapV2Pair(_uniswapV2Pair);
        Pool = _uniswapV2Pair;
        fireSoul = _fireSoul;
        ratioAmount = 1000;
        flm = _flm;
        fdt = _fdt;
        Weights[0] = 1;
        Weights[1] = 2;
        Weights[3] = 3;
        Weights[6] = 4;
        Weights[12] = 5;
        Weights[24] = 6;
        Weights[36] = 7;
        sbt001 = _sbt001;
        sbt005 = _sbt005;
    }
    function setratioAmount(uint256 _ratioAmount) public onlyOwner{
        ratioAmount = _ratioAmount;
    }
    function setSbt001(address _sbt001) public onlyOwner {
        sbt001 = _sbt001;
    }
    function setSbt005(address _sbt005) public onlyOwner {
        sbt005 = _sbt005;
    }
    function setFlmAddress(address _flm) public onlyOwner {
        flm = _flm;
    }
    function setREWARD_CYCLE(uint256 _several) public onlyOwner {
        FLM_AMOUNT = IERC20(flm).balanceOf(address(this)); 
        REWARD_CYCLE =  _several * ONE_MONTH;
    }

    function lockLp(uint256 _several,uint256 _LPAmount) public {
        require(IFireSoul(fireSoul).checkFID(msg.sender),"you don't have fid yet");
        require(IERC20(Pool).balanceOf(msg.sender) >= _LPAmount,'Your Lp quota is insufficient');
        require(
                _several == 0 ||
                _several == 1 || 
                _several == 3 ||
                _several == 6 ||
                _several == 12||
                _several == 24||
                _several == 36 ,
                "Please enter the correct lock-up month");
            address receiver = IFireSoul(fireSoul).getSoulAccount(msg.sender);
            uint256 amount0 = _LPAmount.mul(IERC20(Pool).balanceOf(fdt)) / uniswapV2Pair.totalSupply();
            uint256 amount1 = _LPAmount.mul(ratioAmount);
            ISbt001(sbt001).mint(receiver, amount0 * Weights[_several]);
            ISbt005(sbt005).mint(receiver, amount1);
            TransferHelper.safeTransferFrom(Pool,msg.sender,address(this),_LPAmount);
    }
    function setWeights(uint256 _month,uint256 _weight) public onlyOwner {
        require(Weights[_month] == 0 , "error setting"); 
        Weights[_month] = _weight;
    }
    function backToken(address _token) public onlyOwner {
        TransferHelper.safeTransfer(_token, msg.sender, IERC20(_token).balanceOf(address(this)));
    }
}