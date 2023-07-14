pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract flm is ERC20{
    constructor() ERC20("FLM","FLM"){
        _mint(msg.sender, 10000000000*10**18);
    }
}