pragma solidity = 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract usdt is ERC20{
    constructor() ERC20("USDT","USDT"){
        _mint(msg.sender, 1000000000000 * 10 **(decimals()));
    }
    function decimals() public pure override returns (uint8) {
        return 6; // Set the desired number of decimals
    }
}