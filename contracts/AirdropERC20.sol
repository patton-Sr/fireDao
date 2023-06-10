// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AirdropERC20 {
    IERC20 public token;
    address public admin;
    uint256 public perAmount;
    address[] public userList;

    mapping(address => bool) public allowAddr;
    mapping(address => uint256[]) public userCanClaim;
    modifier onlyAdmin {
        require(msg.sender == admin,"no access");
        _;
    }
    constructor(IERC20 _token,address _admin, address[] memory _userList,uint256 _perAmount ){
        token = _token;
        admin = _admin;
        userList = _userList;
        perAmount = _perAmount;
    }
    function setallowAddr(address _addr, bool _set) public onlyAdmin {
        allowAddr[_addr] = _set;
    }
    function addClaimList(address _user, uint256 _amount) public {
        require(allowAddr[msg.sender], 'address error');
        
    }
    
    function Claim() public {
        for(uint i =0; i<userList.length;i++){
            if(msg.sender == userList[i]){
                token.transfer(msg.sender, perAmount);
            }
        }
    }

    function remaining() public onlyAdmin {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}