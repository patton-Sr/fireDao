pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/TransferHelper.sol";

contract FlameExchangeFdt is Ownable{

    bool public status;
    uint256 public minAmount;
    address public flame;
    address public fdt;
    uint256 public exchangeRatio;

    constructor(address _fdt,address _flame){
        fdt = _fdt;
        flame = _flame;
        exchangeRatio= 1000;
    }
    function setstatus() public onlyOwner{
        status = !status;
    }
    function setexchangeRatio(uint256 _exchangeRatio) public onlyOwner {
        exchangeRatio = _exchangeRatio;
    }
    function setMinAmount(uint256 _amount) public onlyOwner{
        minAmount = _amount;
    }
    function backToken(uint256 _amount) public onlyOwner{
        require(IERC20(fdt).balanceOf(address(this)) >= _amount);
        TransferHelper.safeTransfer(fdt, msg.sender, _amount);
    }
    function exchange(uint256 _amount) public {
        require(!status)
        require(_amount >= minAmount,"The quantity you buy must be greater than the minimum quantity");
        TransferHelper.safeTransferFrom(flame, msg.sender, address(this), _amount);
        TransferHelper.safeTransfer(fdt, msg.sender, _amount/exchangeRatio);
    }
}