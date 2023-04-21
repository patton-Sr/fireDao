//File:./interface/IFireLockFactory.sol
pragma solidity ^0.8.0;
interface IFireLockFactory {
     function addLockItem(
        address _lockAddr,
        string memory _title,
        string memory _token,
        uint256 _lockAmount, 
        uint256 _lockTime, 
        uint256 _cliffPeriod, 
        uint256 _unlockCycle,
        uint256 _unlockRound,
        uint256 _ddl,
        address _admin
        ) external;
}
//File:./interface/ITreasuryDistributionContract.sol
pragma solidity ^0.8.0;

interface ITreasuryDistributionContract {
  function AllocationFund() external;
  function setSourceOfIncome(uint num,uint tokenNum,uint256 amount) external;
}
//File:./interface/IFireLockFeeTransfer.sol
pragma solidity ^0.8.0;
interface IFireLockFeeTransfer {
    function getAddress() external view returns(address);
    function getFee() external view returns(uint256);
    function getUseTreasuryDistributionContract() external view returns(bool);
}
//File:./lib/TransferHelper.sol


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

//File:./interface/IWETH.sol
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

//File:./interface/IERC20ForLock.sol
pragma solidity ^0.8.0;


interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FireLock {

    struct LockDetail{
        string LockTitle;
        uint256 ddl;
        uint256 startTime;
        address admin;
        uint256 amount;
        uint256 unlockCycle;
        uint256 unlockRound;
        uint256[] rate;
        address token;
        address[] member;
        uint256 cliffPeriod;
    }
    struct unLockRecord{
        address user;
        uint256 amount;
        uint256 time;
    }
    bool public lockStatus;
    bool public unlockStatus;
    address public weth;
    address public factoryAddr;
    address public treasuryDistributionContract;
    address public fireLockFeeTransfer;
    address public adminForLock;
    address public createUser;
    uint256 public ONE_DAY_TIME_STAMP = 86400;
    uint256 public totalAmount;
    LockDetail public adminLockDetail;
    unLockRecord[] public record;
    mapping(address => uint256) public claimed;
    mapping(address => uint256) private userTime;
    mapping(address => uint256) public remaining;

    modifier lock() {
    require(lockStatus,"You have already locked the position");
        _;
    }
    modifier unlock(){
        require(unlockStatus,"The contract has already terminated");
        _;
    }

    constructor(address _weth,address _fireLockFeeTransfer,address _treasuryDistributionContract,address _factoryAddr,address _createUser) {
        weth = _weth;
        fireLockFeeTransfer = _fireLockFeeTransfer;
        treasuryDistributionContract = _treasuryDistributionContract;
        factoryAddr = _factoryAddr;
        createUser = _createUser;
        lockStatus = true;
        unlockStatus = true;
    }

    function checkRateForLock(uint256[] memory _rate) public  pure  returns(bool) {
    uint256 _totalRate;
    for(uint256 i = 0 ; i < _rate.length; i++) {
        _totalRate += _rate[i];
    }
    if(_totalRate == 100){
        return true;
    }else{
        return false;
    }
    }

function Lock(
    address _token,
    address _admin,
    uint256 _unlockCycle,
    uint256 _unlockRound,
    uint256 _amount,
    address[] memory _to,
    uint256[] memory _rate,
    string memory _title,
    uint256 _cliffPeriod
) public payable  lock {
    require(_to.length == _rate.length , "user amount error");
    require(msg.sender == createUser, "you are not creat user");
    require(block.timestamp + _unlockCycle * _unlockRound * ONE_DAY_TIME_STAMP > block.timestamp, "Deadline should be bigger than current block number");
    require(_amount > 0, "Token amount should be bigger than zero");
    require(checkRateForLock(_rate),"rate error");
    address owner = msg.sender;
    uint256 cliffPeriod = block.timestamp + _cliffPeriod * ONE_DAY_TIME_STAMP;
    uint256 _ddl = block.timestamp + _unlockCycle * _unlockRound * ONE_DAY_TIME_STAMP + _cliffPeriod * ONE_DAY_TIME_STAMP;

    if (msg.value == 0) {
        TransferHelper.safeTransferFrom(weth, msg.sender, feeReceiver(), feeAmount());
    } else {
        require(msg.value == feeAmount(), 'Amount error');
        IWETH(weth).deposit{value: feeAmount()}();
        IWETH(weth).transfer(feeReceiver(), feeAmount());
    }
    

    LockDetail memory _LockDetail = LockDetail({
        LockTitle: _title,
        ddl: _ddl,
        startTime: cliffPeriod,
        admin: _admin,
        amount: _amount,
        unlockCycle: _unlockCycle,
        unlockRound: _unlockRound,
        rate: _rate,
        token: _token,
        member: _to,
        cliffPeriod: cliffPeriod
    });

    adminLockDetail = _LockDetail;

    IERC20(_token).transferFrom(owner, address(this), _amount);
    lockStatus = false;

    IFireLockFactory(factoryAddr).addLockItem(
        address(this),
        _LockDetail.LockTitle,
        getTokenSymbol(),
        _LockDetail.amount,
        block.timestamp,
        _LockDetail.startTime,
        _LockDetail.unlockCycle,
        _LockDetail.unlockRound,
        _LockDetail.ddl,
        _LockDetail.admin
    );
    totalAmount =  _LockDetail.amount;
}

function isUserUnlock(address _user) public view returns(uint256 _userId) {
    uint256 len = adminLockDetail.member.length;
    for(uint256 i = 0 ; i < len; i++){
        if(_user == adminLockDetail.member[i]){
            return i;
        }
    }
    require(false,"You are not a user of this lock address");
}

function claim(uint256 _amount) public unlock {
    require(checkRate() == 100 ,"rate is error");
    require(block.timestamp > adminLockDetail.cliffPeriod * ONE_DAY_TIME_STAMP,"still cliffPeriod");
    uint256 amountOfUser = totalAmount;
    address _token = adminLockDetail.token;
    uint256 balance = IERC20(_token).balanceOf(address(this));
    uint256 amount = balance < amountOfUser ? balance : amountOfUser;
    uint256 userId = isUserUnlock(msg.sender);
    uint256 timeA;

    if(userTime[msg.sender] == 0){
        timeA = block.timestamp - adminLockDetail.cliffPeriod;
    } else {
        timeA = block.timestamp - userTime[msg.sender]; 
    }

    uint256 timeB = adminLockDetail.unlockCycle * ONE_DAY_TIME_STAMP * adminLockDetail.unlockRound;
    uint256 _unlockAmount = (amountOfUser * adminLockDetail.rate[userId]/100)*(timeA/timeB);
    if(remaining[msg.sender] != 0) {
        if(_amount > _unlockAmount && _amount < _unlockAmount + remaining[msg.sender]){
            IERC20(_token).transfer(msg.sender, _amount);
            adminLockDetail.amount -= _amount;
            userTime[msg.sender] = block.timestamp;
            remaining[msg.sender] = _unlockAmount + remaining[msg.sender] - _amount;
            unLockRecord memory _unlockRecord = unLockRecord({
                user:msg.sender,
                amount:_amount,
                time: block.timestamp
            });
            record.push(_unlockRecord);
            claimed[msg.sender] += _amount;
            if(adminLockDetail.amount == 0){
                unlockStatus = false;
            }

        }
    } else if(amount >= amountOfUser && _amount <= _unlockAmount){
        IERC20(_token).transfer(msg.sender, _amount);
        adminLockDetail.amount -= _amount;
        userTime[msg.sender] = block.timestamp;
        remaining[msg.sender] = _unlockAmount - _amount;
        unLockRecord memory _unlockRecord = unLockRecord({
            user:msg.sender,
            amount:_amount,
            time: block.timestamp
        });
        record.push(_unlockRecord);
        claimed[msg.sender] += _amount;
        if(adminLockDetail.amount == 0){
            unlockStatus = false;
        }

    } else {
        revert();

    }
}

    function checkRate() public view returns(uint) {
        uint totalRate;
        for(uint i =0; i < adminLockDetail.rate.length; i++ ){
            totalRate += adminLockDetail.rate[i];
        }
        return totalRate;
    }

    function changeLockAdmin(address _to) public unlock {
    address sender = msg.sender;
    address lockAdmin = adminLockDetail.admin;

    require(lockAdmin != address(0), "Lock admin must exist");
    require(lockAdmin == sender, "Sender must be admin");
    adminLockDetail.admin = _to;
    }

    function setLockMemberAddr(uint256 _id, address _to) public  unlock {
        require(adminLockDetail.member.length > 1, "user amount error");
        require(msg.sender == adminLockDetail.admin);
        adminLockDetail.member[_id] = _to;
    }
  
    function checkGroupMember() public view returns(address[] memory){
        return adminLockDetail.member;
    }
    function setMemberRate(uint[] memory _rate) public {
        require(msg.sender == adminLockDetail.admin);
        require(_rate.length == adminLockDetail.rate.length , "rate is not match");
        for(uint256 i =0; i< adminLockDetail.rate.length ;i++){
        adminLockDetail.rate[i] = _rate[i];
        }
    }
    
    function isClaim(uint256 userId) public view returns(uint256) {
        address _user = adminLockDetail.member[userId];
        if(userTime[_user] == 0 ){
        return (totalAmount * adminLockDetail.rate[userId]/100/adminLockDetail.unlockRound) * (block.timestamp - adminLockDetail.startTime)/
        adminLockDetail.unlockCycle * ONE_DAY_TIME_STAMP;
        }else{
        return (totalAmount * adminLockDetail.rate[userId]/100/adminLockDetail.unlockRound) * (block.timestamp - userTime[_user])/
        adminLockDetail.unlockCycle * ONE_DAY_TIME_STAMP;
        }

    }
 
    function getLockTitle() public view returns(string memory) {
        return adminLockDetail.LockTitle;
    }
   
    function getTokenSymbol() public view returns(string memory) {
        return IERC20(adminLockDetail.token).symbol();
    }

    function feeAmount() public view returns(uint256) {
        return IFireLockFeeTransfer(fireLockFeeTransfer).getFee();
    }
    function feeReceiver() public view returns(address) {
        return IFireLockFeeTransfer(fireLockFeeTransfer).getAddress();
    }
    
    function getMember() public view returns(address[] memory) {
        return adminLockDetail.member;
    }
    function getMemberRate() public view returns(uint256[] memory) {
        return adminLockDetail.rate;
    }
    function getMemberAmount() external view returns(uint256) {
        return adminLockDetail.member.length;
    }
    function getRecordLength() external view returns(uint256) {
        return record.length;
    }
}