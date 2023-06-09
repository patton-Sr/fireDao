// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Address.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IReputation.sol";

contract MarketValueManager is Ownable {
    IERC20 public weth;
    address public token;
    uint256 public cooldown;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) public isOrNotUseWallet;
    address public cityNodeAddress;
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        uniswapV2Router = _uniswapV2Router;
        weth = IERC20(uniswapV2Router.WETH());
        weth.approve(address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3), 10**34);
        weth.approve(address(this), 10**34);
    }
    modifier notContract() {
        require(!Address.isContract(msg.sender), "No contracts");
        _;
    }
    function setcityNodeAddress(address _cityNodeAddress) public onlyOwner {
        cityNodeAddress = _cityNodeAddress;
    }

    function buyAndBurn() public  {
        require(weth.balanceOf(address(this)) >=10 **18 , "BNB balance error");
        require(block.timestamp > cooldown + 300 , "is not cooldown");
        require(IERC20(token).balanceOf(msg.sender) > 1000*10**18,"u hold amount error" );
        if(block.timestamp - isOrNotUseWallet[msg.sender] < 3600){
            revert();
        }
        swapTokensForOther(10**18);
        isOrNotUseWallet[msg.sender] = block.timestamp;
        cooldown = block.timestamp;
    }
   
    function checkSAFEBalance() public view returns(uint256){
        return IERC20(token).balanceOf(address(this));
    }

    function checkBNBBalance() public view returns(uint256) {
        return weth.balanceOf(address(this));
    }
 
    function setAimToken(address _token) public onlyOwner {
        token = _token;
    }
    


    function swapTokensForOther(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = token ;//testnet
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        IERC20(token).transfer(address(0x000000000000000000000000000000000000dEaD), checkSAFEBalance()/100*95);
        IERC20(token).transfer(msg.sender, checkSAFEBalance()/100*5);
    }
    function withdraw() public onlyOwner{
        weth.transfer(msg.sender, checkBNBBalance());
    }
}