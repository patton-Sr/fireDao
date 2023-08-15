pragma solidity  ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FireSeedCoupon is ERC20 , Ownable{
    address exchangeFireseed;
    address ogContract;
    constructor(uint256 initialSupply) ERC20("FSCoupon","FSC"){
        _mint(msg.sender, initialSupply);
    }
    modifier onlyExchangeFireSeed() {
        require(msg.sender == exchangeFireseed,"no access");
        _;
    }
  
    function _mintExternal(address _to, uint256 _amount) external {
        require(msg.sender == ogContract,"no access");
        _mint(_to, _amount);
    } 
    function setOgContract(address _ogContract) public onlyOwner{
        ogContract = _ogContract;
    }
    function setExchangeFireSeed(address _exchangeFireseed) public onlyOwner{
        exchangeFireseed = _exchangeFireseed;
    }
    function transfer(address recipient, uint256 amount) public override onlyExchangeFireSeed returns (bool)  {
        
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override onlyExchangeFireSeed returns (bool)  {
        super.transferFrom(sender, recipient, amount);
        return true;
    }
    function burn(uint256 amount) public {
        require(msg.sender == ogContract,"no access");
        _burn(msg.sender, amount);
    }
}