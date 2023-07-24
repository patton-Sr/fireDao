pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20{
  address owner;
    constructor() ERC20("USDT","USDT"){
        owner =msg.sender;
        _mint(msg.sender, 100000000000);
        
    }
    function mint(uint256 _amount) public  {
        require(msg.sender == owner);
        _mint(msg.sender,_amount);
    }
     function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}