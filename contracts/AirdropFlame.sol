//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./lib/TransferHelper.sol";
import "./interface/IFirePassport.sol";
import "./interface/IFireSoul.sol";


contract airdropFlm is Ownable,Pausable,ReentrancyGuard {
    struct airDropListInfo{
        address user;
        uint256 amount;
        string introduction;
    }
    address firePassport;
    uint256 private id;
    address public flm;
    using EnumerableSet for EnumerableSet.AddressSet;
    airDropListInfo[] public airDropListInfos;
    EnumerableSet.AddressSet private adminsLevelTwo;
    EnumerableSet.AddressSet private airDropList;
    mapping (address => uint256) public userIds;
    mapping(address => uint256) public userTotalClaim;
    mapping(address => address) public fromLevelTwo;
    mapping(address => address[]) public levelTwoAdds;
    event Claimed(uint pid,string username ,address user, uint256 amount);
    event ClaimRecord(uint256 id,uint pid,string username ,address user, uint256 amount);

    modifier onlyAdminTwo {
        require(checkIsNotAdminsLevelTwo(msg.sender),'you are not admin level two');
        _;

    }
    modifier onlyWhiteListUser{
        require(checkIsNotWhiteListUser(msg.sender),'you are not whitelist user');
        _;
    }
    constructor(address _token, address _firePassport) {
        flm = _token;
        firePassport = _firePassport;
    }
  
    function setFlm(address _Flm) public onlyOwner {
        flm = _Flm;
    }

    function setAdminsLevelTwo(address[] memory _addr) public onlyOwner{
        for(uint256 i = 0 ; i < _addr.length ; i ++){
            adminsLevelTwo.add(_addr[i]);
        }
    }   
    function checkIsNotWhiteListUser(address _address) internal view returns(bool){
        return airDropList.contains(_address);
    }
    function checkIsNotAdminsLevelTwo(address _address) internal view returns (bool) {
        return adminsLevelTwo.contains(_address);
    }
    
    function checkUserCanClaim(address _addr) public view returns(uint256) {
        uint256 total = 0 ;
        for(uint256 i =0 ; i< airDropListInfos.length ; i++){
            if(_addr == airDropListInfos[i].user){
                total = airDropListInfos[i].amount;
            }
        }
        return total;
    }
  
    function removeAdminsLevelTwo(address[] memory _addr) public onlyOwner {
           for(uint256 i = 0 ; i < _addr.length ; i ++){
               require(checkIsNotAdminsLevelTwo(_addr[i]), 'the address is not admin level two');
            adminsLevelTwo.remove(_addr[i]);
        }
    }
    function checkUserId(address _addr) internal view returns(uint256) {
         return userIds[_addr];
    }
    function addAirDropList(address[] memory _addr, uint256[] memory _amount, string memory _info) public whenNotPaused onlyAdminTwo{
        for(uint256 i = 0; i< _addr.length ; i++){
            if(checkIsNotWhiteListUser(_addr[i])){
                airDropListInfos[checkUserId(_addr[i])].amount += _amount[i];
            }else{
            fromLevelTwo[_addr[i]] = msg.sender;
            levelTwoAdds[msg.sender].push(_addr[i]);
            airDropList.add(_addr[i]);
            airDropListInfo memory info = airDropListInfo({user:_addr[i], amount:_amount[i],introduction:_info });
            airDropListInfos.push(info);
            userIds[_addr[i]] = airDropListInfos.length - 1;

            }
            emit ClaimRecord(id,getPid(_addr[i]),getName(_addr[i]), _addr[i], _amount[i]);
            id++;
        }
    }
    function reomove(address _addr) internal {
        for(uint256 i = 0 ; i < airDropListInfos.length; i++){
            if(_addr == airDropListInfos[i].user){
                airDropListInfos[i] = airDropListInfos[airDropListInfos.length -1 ];
                airDropListInfos.pop();
                break;
            }
        }
    }
    function reduceAmount(address _addr,uint256 _amount) internal {
            for(uint256 i = 0 ; i < airDropListInfos.length; i++){
            if(_addr == airDropListInfos[i].user){
                airDropListInfos[i].amount -= _amount;
                break;
            }
        }
    }
    function removeWhiteList( address[] memory _addr) public onlyAdminTwo {
         for(uint256 i = 0; i< _addr.length ; i++){
             require(checkIsNotWhiteListUser(_addr[i]),'the address is not whitelist user');
            airDropList.remove(_addr[i]);
            reomove(_addr[i]);
        }
    }
    function deposit(address _token, uint256 _amount) public onlyOwner {
        TransferHelper.safeTransferFrom(_token, msg.sender, address(this),_amount);
    }
    function backToken(address _token , uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }
    function Claim(uint256 _amount) public  whenNotPaused nonReentrant  onlyWhiteListUser{
        require(checkUserCanClaim(msg.sender) >= _amount, "Insufficient quantity available for extraction");
        require(contractAmount()> _amount,"Insufficient quantity available for extraction");
        IERC20(flm).transfer(msg.sender, _amount);
        reduceAmount(msg.sender,_amount);
        userTotalClaim[msg.sender] += _amount;
        emit Claimed(getPid(msg.sender),getName(msg.sender),  msg.sender, _amount);

    }
    function getName(address _user) public view returns(string memory){
        if(IFirePassport(firePassport).hasPID(_user)){
        return IFirePassport(firePassport).getUserInfo(_user).username;
        }
        return "anonymous";
    }
 
    function getPid(address _user) public view returns(uint) {
        if(IFirePassport(firePassport).hasPID(_user)){
        return IFirePassport(firePassport).getUserInfo(_user).PID;
        }
        return 0;
    }
    function getAdminsLevelTwoList() external view returns(address[] memory){
        return adminsLevelTwo.values();
    }
    function getWhiteList() external view returns(address[] memory) {
        return airDropList.values();
    }
   function getAdminsLevelTwoLength() external view returns (uint256) {
        return adminsLevelTwo.length();
    }
    function getWhiteListLength() external view returns(uint256) {
        return airDropList.length();
    }
    function getAdminAddsLength(address _user) external view returns(uint256) {
        return levelTwoAdds[_user].length;
    }
      function contractAmount() public view returns(uint256){
        return IERC20(flm).balanceOf(address(this));
    }
        /**
     * @dev Pause .
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Resume .
     */
    function unpause() external onlyOwner {
        _unpause();
    }
} 