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
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
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

    struct groupLockDetail{
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
        bool isNotchange;
        uint256 cliffPeriod;
    }
    bool public lockStatus;
    bool public unlockStatus;
    address public weth;
    address public treasuryDistributionContract;
    address public fireLockFeeTransfer;
    uint256 public ONE_DAY_TIME_STAMP = 86400;
    uint256 public index;
    address[] public ListTokenAddress;
    mapping(address => address) adminAndOwner;
    mapping(address => address[]) public tokenAddress;
    mapping(address => groupLockDetail[]) public adminGropLockDetail;
    groupLockDetail[] public ListGropLockDetail;

    constructor(address _weth,address _fireLockFeeTransfer,address _treasuryDistributionContract) {
        weth = _weth;
        fireLockFeeTransfer = _fireLockFeeTransfer;
        treasuryDistributionContract = _treasuryDistributionContract;
        lockStatus = true;
        unlockStatus = true;
    }

function groupLock(
    address _token,
    uint256 _unlockCycle,
    uint256 _unlockRound,
    uint256 _amount,
    address[] memory _to,
    uint256[] memory _rate,
    string memory _title,
    uint256 _cliffPeriod,
    bool _isNotchange
) public payable {
    require(lockStatus,"You have already locked the position");
    require(block.timestamp + _unlockCycle * _unlockRound * ONE_DAY_TIME_STAMP > block.timestamp, "Deadline should be bigger than current block number");
    require(_amount > 0, "Token amount should be bigger than zero");
    address owner = msg.sender;
    uint256 cliffPeriod = block.timestamp + _cliffPeriod;
    if (msg.value == 0) {
        TransferHelper.safeTransferFrom(weth, msg.sender, feeReceiver(), feeAmount());
    } else {
        require(msg.value == feeAmount(), 'Amount error');
        IWETH(weth).deposit{value: feeAmount()}();
        IWETH(weth).transfer(feeReceiver(), feeAmount());
    }

    groupLockDetail memory _groupLockDetail = groupLockDetail({
        LockTitle: _title,
        ddl: block.timestamp + _unlockCycle * _unlockRound * ONE_DAY_TIME_STAMP + _cliffPeriod * ONE_DAY_TIME_STAMP,
        startTime: cliffPeriod,
        admin: msg.sender,
        amount: _amount,
        unlockCycle: _unlockCycle,
        unlockRound: _unlockRound,
        rate: _rate,
        token: _token,
        member: _to,
        isNotchange: _isNotchange,
        cliffPeriod: cliffPeriod
    });

    ListTokenAddress.push(_token);
    ListGropLockDetail.push(_groupLockDetail);
    adminGropLockDetail[msg.sender].push(_groupLockDetail);

    IERC20(_token).transferFrom(owner, address(this), _amount);
    lockStatus = false;
}

    function groupUnLock(uint256 _index,address _token) public {
        require(unlockStatus,"The contract has already terminated");
        require(checkRate(msg.sender, _index) == 100 ,"rate is error");
        require(block.timestamp >= adminGropLockDetail[msg.sender][_index].ddl,"current time should be bigger than deadlineTime");
        uint256 amountOfUser = adminGropLockDetail[msg.sender][_index].amount;
        uint256 amount = IERC20(_token).balanceOf(address(this));
        if(amount > amountOfUser  || amount == amountOfUser){
            for(uint i = 0 ; i < adminGropLockDetail[msg.sender][_index].member.length;i++){
            IERC20(_token).transfer(adminGropLockDetail[msg.sender][_index].member[i], (amountOfUser * adminGropLockDetail[msg.sender][_index].rate[i]/100)/adminGropLockDetail[msg.sender][_index].unlockRound*(block.timestamp - adminGropLockDetail[msg.sender][_index].startTime)/
            ONE_DAY_TIME_STAMP);
            adminGropLockDetail[msg.sender][_index].amount -= (amountOfUser*adminGropLockDetail[msg.sender][_index].rate[i]/100)/(adminGropLockDetail[msg.sender][_index].unlockRound*adminGropLockDetail[msg.sender][_index].unlockRound)*(block.timestamp - adminGropLockDetail[msg.sender][_index].startTime)/
            ONE_DAY_TIME_STAMP;
            }
            adminGropLockDetail[msg.sender][_index].startTime =block.timestamp;
            if(amountOfUser == 0){
                unlockStatus = false;
            }
        }else{revert();}
        
        
    }
    
    function checkRate(address _user, uint256 _index) public view returns(uint) {
        uint totalRate;
        for(uint i =0; i < adminGropLockDetail[_user][_index].rate.length; i++ ){
            totalRate += adminGropLockDetail[_user][_index].rate[i];
        }
        return totalRate;
    }

 function changeLockAdmin(address _to, uint _index) public {
    address sender = msg.sender;
    address lockAdmin = adminGropLockDetail[adminAndOwner[sender]][_index].admin;
    bool isNotChange = adminGropLockDetail[adminAndOwner[sender]][_index].isNotchange;

    require(unlockStatus,"The contract has already terminated");
    require(lockAdmin != address(0), "Lock admin must exist");
    require(!isNotChange, "Cannot change admin when isNotchange is true");

    if (adminAndOwner[sender] == address(0)) {
        require(lockAdmin == sender, "Sender must be admin");
        adminGropLockDetail[sender][_index].admin = _to;
        adminAndOwner[_to] = sender;
    } else {
        require(lockAdmin == sender, "Sender must be admin");
        adminGropLockDetail[adminAndOwner[sender]][_index].admin = _to;
        adminAndOwner[_to] = adminAndOwner[sender];
    }
}

    function setIsNotChange(uint _index) public {
        require(unlockStatus,"The contract has already terminated");
        if(adminAndOwner[msg.sender] == address(0)){
        require(msg.sender == adminGropLockDetail[msg.sender][_index].admin,"you are not admin");
        adminGropLockDetail[msg.sender][_index].isNotchange = !adminGropLockDetail[msg.sender][_index].isNotchange;
        }else{
        require(msg.sender == adminGropLockDetail[adminAndOwner[msg.sender]][_index].admin,"you are not admin");
        adminGropLockDetail[adminAndOwner[msg.sender]][_index].isNotchange = !adminGropLockDetail[adminAndOwner[msg.sender]][_index].isNotchange;
        }
    }
    
    function addLockMember(address _to, uint _index, uint _rate) public {
        require(unlockStatus,"The contract has already terminated");
        require(msg.sender == adminGropLockDetail[msg.sender][_index].admin);
        if(adminGropLockDetail[msg.sender][_index].rate[0]-_rate > 0){
        adminGropLockDetail[msg.sender][_index].rate[0]-_rate;
        }else{
            revert();
        }
        adminGropLockDetail[msg.sender][_index].member.push(_to);
        adminGropLockDetail[msg.sender][_index].rate.push(_rate);
    }

    function removeLockMember(uint _index, address _to) public {
        require(unlockStatus,"The contract has already terminated");
        require(msg.sender == adminGropLockDetail[msg.sender][_index].admin);
        for(uint i = 0; i < adminGropLockDetail[msg.sender][_index].member.length; i++){
            if(_to == adminGropLockDetail[msg.sender][_index].member[i]){
                uint id = i;
                adminGropLockDetail[msg.sender][_index].member[id] = adminGropLockDetail[msg.sender][_index].member[adminGropLockDetail[msg.sender][_index].member.length -1];
                adminGropLockDetail[msg.sender][_index].member.pop();
            }
        }
    }
    function checkGroupMember(address admin, uint _index) public view returns(address[] memory){
        return adminGropLockDetail[admin][_index].member;
    }
    function setGroupMemberRate(uint _index, uint[] memory _rate) public {
        require(msg.sender == adminGropLockDetail[msg.sender][_index].admin);
        for(uint i =0; i< adminGropLockDetail[msg.sender][_index].rate.length ;i++){
        adminGropLockDetail[msg.sender][_index].rate[i] = _rate[i];
        }
    }
    

    function getGroupLockTitle(uint _index) public view returns(string memory) {
        return adminGropLockDetail[msg.sender][_index].LockTitle;
    }

    function getTokenName(uint _index) public view returns(string memory) {
        return IERC20(adminGropLockDetail[msg.sender][_index].token).name();
    }

    function getTokenSymbol(uint _index) public view returns(string memory) {
        return IERC20(adminGropLockDetail[msg.sender][_index].token).symbol();
    }

    function getTokenDecimals(uint _index) public view returns(uint) {
        return IERC20(adminGropLockDetail[msg.sender][_index].token).decimals();
    }

    function getOwnerTokenList() public view returns(address[] memory) {
        return tokenAddress[msg.sender];
    }
    function getTokenList() public view returns(address[] memory) {
        return ListTokenAddress;
    }
    function feeAmount() public view returns(uint256) {
        return IFireLockFeeTransfer(fireLockFeeTransfer).getFee();
    }
    function feeReceiver() public view returns(address) {
        return IFireLockFeeTransfer(fireLockFeeTransfer).getAddress();
    }

    function ListGropLockDetailLength() public view returns(uint256) {
        return ListGropLockDetail.length;
    }
    function getGroupMember(uint256 _index) public view returns(address[] memory) {
        return ListGropLockDetail[_index].member;
    }
    function getGroupMemberAmount(uint256 _index) external view returns(uint256) {
        return ListGropLockDetail[_index].member.length;
    }
}