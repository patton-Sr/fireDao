// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IReputation.sol";



contract TreasuryDistributionContract is Ownable {
    uint256 public intervalTime;
    uint256 public firstTime;
    address[] public AllocationFundAddress;
    uint public rate;
    uint public userTime;
    bool public pause;
    address public controlAddress;
    address public Reputation;
    uint256 public ReputationAmount;
    address public weth;
    uint public allTokenNum;
    mapping(address => uint) public distributionRatio;
    mapping(address => uint256) public AllocationFundUserTime;
    mapping(uint =>mapping(uint => uint256[])) public sourceOfIncome;
    mapping(uint => address) public tokenList;
    mapping(address => bool) public allowAddr;
    constructor()  {
        rate = 80;
        intervalTime = 3600;
        ReputationAmount = 0;
        userTime = 43200;
    }

    //onlyOwner
    function setRate(uint _rate) public onlyOwner{
        rate = _rate;
    }
    function setAllowAddr(address _addr, bool _status) public onlyOwner{
        allowAddr[_addr] = _status;
    }
    function setWeth(address _weth) public onlyOwner{
        weth = _weth;
    }
    function setIntervalTime(uint256 _time) public onlyOwner{
        intervalTime = _time;
    }
    function setUerIntverTime(uint256 _time) public onlyOwner{
        userTime = _time;
    }
    function setTotalDistributionRatio(address _addr, uint _rate) public onlyOwner{
        require(_addr != address(0), "FireDao: address is not be zero address");
        require(_rate <= 100, "FireDao: rate must be small 100 ");
        distributionRatio[_addr] = _rate;
    }
    
    function removeAddr(address _addr) public onlyOwner{
        uint _num;
        for(uint i = 0; i<AllocationFundAddress.length;i++){
            if(AllocationFundAddress[i] == _addr){
                _num = i;
            }
        }
        AllocationFundAddress[_num] = AllocationFundAddress[AllocationFundAddress.length - 1];
        AllocationFundAddress.pop();
        delete distributionRatio[_addr];
    }
    function addTokenList(address tokenAddr)public onlyOwner {
        tokenList[allTokenNum] = tokenAddr;
        allTokenNum ++;
    }
    function deleteTokenList() public
    function setReputation(address _Reputation) public onlyOwner{
        Reputation = _Reputation;
    }
    
    function setControlAddress(address _controlAddress) public onlyOwner{
        controlAddress = _controlAddress;
    }
    
    function addAllocationFundAddress(address[] memory assigned) public onlyOwner {
        
        for(uint i = 0 ; i < assigned.length ; i++){
            require(assigned[i] != address(0), "FireDao: allocation Address is not zero address");
            AllocationFundAddress.push(assigned[i]);
        }
    }
    function setAddr(uint256 _id,address _addr) public onlyOwner{
        require(_addr != address(0) , "the address is not be zero address");
        AllocationFundAddress[_id] = _addr;
    }
    function withdraw(uint256 _tokenNum) public onlyOwner {
        IERC20(tokenList[_tokenNum]).transfer(msg.sender, IERC20(tokenList[_tokenNum]).balanceOf(address(this)));
    }
    //getSource
    function setSourceOfIncome(uint num,uint tokenNum,uint256 amount) external {
        require(allowAddr[msg.sender],"FireDao: no access");
        sourceOfIncome[num][tokenNum].push(amount);
    }
    function getSourceOfIncomeLength(uint num,uint tokenNum) public view returns(uint256){
        return sourceOfIncome[num][tokenNum].length;
    }
    function getSourceOfIncome(uint num , uint tokenNum) public view returns(uint256[] memory){
        return sourceOfIncome[num][tokenNum];
    }
    function getWETHBalance() public view returns(uint256){
        return IERC20(weth).balanceOf(address(this));
    }
    //main
    function setStatus() external {
        require(msg.sender == controlAddress || msg.sender == owner(),"FireDao: the callback address is error");
        pause = !pause;
    }
    function setReputationAmount(uint256 _amount) public onlyOwner{
        ReputationAmount = _amount; 
    }
    
    function AllocationFund(uint _tokenNum) public {
        require(!pause, "FireDao: contract is pause");
        require(checkRate() == 100,'rate error');
        require(IReputation(Reputation).checkReputation(msg.sender) > ReputationAmount*10*18 || msg.sender == owner() ,"Reputation Points is not enough");
        require( block.timestamp > firstTime + intervalTime ,"FireDao: AllocationFund need interval 30 minute");
        require( block.timestamp >  AllocationFundUserTime[msg.sender] + userTime ,"FireDao: wallet need 12 hours to callback that");
        require(getWETHBalance() > 0, "FireDao: the balance of WETH is error");
        uint256 totalBalance = getTokenBalance(_tokenNum);
        for(uint i = 0 ; i < AllocationFundAddress.length; i ++){
        ERC20(tokenList[_tokenNum]).transfer(AllocationFundAddress[i], totalBalance * rate * distributionRatio[AllocationFundAddress[i]]/10000);
    }
        firstTime = block.timestamp;
        AllocationFundUserTime[msg.sender] = block.timestamp;
        IERC20(weth).transfer(msg.sender, 5 * 10**16);
    }
    function checkRate() public view returns(uint256){
        uint256 num;
        for(uint i = 0; i < AllocationFundAddress.length;i++){
            num += distributionRatio[AllocationFundAddress[i]];
        }
        return num;
    }
    function getTokenBalance(uint num) public view returns(uint256) {
        return IERC20(tokenList[num]).balanceOf(address(this));
    }
    function getAllocationFundAddressLength() public view returns(uint256) {
        return AllocationFundAddress.length;
    }

}