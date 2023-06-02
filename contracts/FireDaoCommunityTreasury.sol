// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IUniswapV2Router02.sol";
import './lib/TransferHelper.sol';

contract FireDaoCommunityTreasury is Ownable {

    IUniswapV2Router02 public uniswapV2Router;
    address[] public multiWallet;
    mapping (address => bool) public isNotMulti;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x2863984c246287aeB392b11637b234547f5F1E70);
        uniswapV2Router = _uniswapV2Router;
    }
    function addmultiWallet(address[] memory _addr) public onlyOwner {
        for(uint256 i = 0 ; i < _addr.length; i ++){
            require(_addr[i] != address(0), 'address error');
            multiWallet.push(_addr[i]);
            isNotMulti[_addr[i]] = true;
        }
    }
    function deleteAddr(address _addr) internal {
        for(uint256 i = 0; i< multiWallet.length ;i ++){
            if(_addr == multiWallet[i]){
                multiWallet[i] = multiWallet[multiWallet.length - 1];
                multiWallet.pop();
                delete isNotMulti[_addr];
            }
        }
    }
    function removemultiWallet(address[] memory _addr) public onlyOwner {
        for(uint256 i = 0 ; i < _addr.length ; i++) {
            require(isNotMulti[_addr[i]],'address error');
            deleteAddr(_addr[i]);
        }
    }
    function withDraw(uint256 _amount) public {
        TransferHelper.safeTransfer(uniswapV2Router.WETH(),)
    }

  
}
