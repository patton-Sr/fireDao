pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract flm is ERC20{
  address owner;
    constructor() ERC20("FLM","FLM"){
        owner =msg.sender;
        _mint(msg.sender, 10000000000000*10**18);
    }
    function mint(uint256 _amount) public  {
        require(msg.sender == owner);
        _mint(msg.sender,_amount);
    }
}