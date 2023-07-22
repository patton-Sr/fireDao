// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interface/IUniswapV2Router02.sol";

contract warp {
    IERC20 public WETH;
    address public owner;
    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x2863984c246287aeB392b11637b234547f5F1E70);
        owner = msg.sender;
        WETH = IERC20(_uniswapV2Router.WETH());
    }
    modifier onlyOwner(){
        require(msg.sender == owner); 
        _;
    }
    function withdraw() external  {
        WETH.transfer(msg.sender,balance());

    }
    function balance() public view returns(uint256){
        return WETH.balanceOf(address(this));
    }
    function withdrawAll() public onlyOwner{
        WETH.transfer(msg.sender,balance());
    }
}
