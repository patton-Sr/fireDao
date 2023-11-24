


// File: contracts/libraries/TransferHelper.sol



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.18;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract FDTOGStaking is Ownable{
    using SafeMath for uint256 ;
    struct userOrderInfo{
        address user;
        uint256 amount;
        uint256 time;
        uint256 startTime;
        uint256 endTime;
        uint256 totalReward;
    }
    address public fdtOg;
    address public flm;
    uint256 public base = 100;
    uint256 public oneBlockTime = 6;
    uint256 public day = 86400;
    uint256 public flmPrice;
    uint256 public fdtOgPrice;
    mapping(uint256 => uint256 ) public dateToRatio;
    mapping(address => userOrderInfo[]) public userOrderInfos;
    constructor(address _flm,address _fdtOg){
        flm = _flm;
        fdtOg = _fdtOg;
        setDateToRatio(0,20 );
        setDateToRatio(90,30 );
        setDateToRatio(180,50 );
        setDateToRatio(270,70 );
        setDateToRatio(360,80 );
        setDateToRatio(720,100 );
        setDateToRatio(1080,130 );

    }
    function setFlmPrice(uint256 _price) public onlyOwner {
        flmPrice = _price;

    }
    function setFdtOgPrice(uint256 _price) public onlyOwner{
        fdtOgPrice = _price;
    }
    function setDateToRatio(uint256 _date , uint256 _ratio) public onlyOwner{
        dateToRatio[_date.mul(day)] = _ratio.div(base);
    }
    function deleteDateToRatio(uint256 _date) public onlyOwner{
        delete dateToRatio[_date.mul(day)];

    }
    function setFlm(address _newFlm) public onlyOwner{
        flm = _newFlm;
    }
    function getFlmAmount() public view returns(uint256){
        return IERC20(flm).balanceOf(address(this));

    }
    function deposit(uint256 _amount) public onlyOwner {
        TransferHelper.safeTransferFrom(flm, msg.sender, address(this), _amount);

    }
    function backToken(uint256 _amount) public onlyOwner {
        TransferHelper.safeTransfer(flm,msg.sender, _amount);
    }
    function annualized(uint256 _amount , uint256 _date) public view returns(uint256){
        return _amount.add(_amount.mul(dateToRatio[_date.mul(day)]).div(base));
    }
    function staking(uint256 _amount,uint256 _date) public {
        require(
            _date == 0  || 
            _date == 90 ||
            _date == 180||
            _date == 270||
            _date == 360||
            _date == 720||
            _date == 1080,
            "input error"
            );
        userOrderInfo memory info = userOrderInfo({
            user:msg.sender,
            amount: _amount,
            time:block.timestamp,
            startTime:block.timestamp,
            endTime: block.timestamp.add(_date.mul(day)),
            totalReward: annualized(_amount,_date)
        });
        userOrderInfos[msg.sender].push(info);
        TransferHelper.safeTransferFrom(fdtOg, msg.sender, address(this),_amount );
    }
    function getBlock(uint256 _time) internal view returns(uint256){
        return _time.div(oneBlockTime);
    }
    function CanClaim(address _user) public view returns(uint256 ){
        uint256 total;
        for(uint256 i = 0 ;i < userOrderInfos[_user].length;i++){
            if(block.timestamp > userOrderInfos[_user][i].time){
                uint256 OneBlockTimeReward = userOrderInfos[_user][i].totalReward.div(getBlock(userOrderInfos[_user][i].endTime.sub(userOrderInfos[_user][i].startTime)));
                total = total.add(getBlock(block.timestamp.sub(userOrderInfos[_user][i].time).mul(OneBlockTimeReward)));
            }
        }
        return total;
    }
    function Claim(address _user) public {
           uint256 total;
        for(uint256 i = 0 ;i < userOrderInfos[_user].length;i++){
            if(block.timestamp > userOrderInfos[_user][i].time){
                uint256 OneBlockTimeReward = userOrderInfos[_user][i].totalReward.div(getBlock(userOrderInfos[_user][i].endTime.sub(userOrderInfos[_user][i].startTime)));
                total = total.add(getBlock(block.timestamp.sub(userOrderInfos[_user][i].time).mul(OneBlockTimeReward)));
                userOrderInfos[_user][i].time = block.timestamp;            }
        }
        TransferHelper.safeTransfer(flm,_user,total);
    }
function getUserOderLength(address _user) public view returns(uint256){
    return userOrderInfos[_user].length;
}

}