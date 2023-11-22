

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
pragma solidity =0.8.18;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IColorNft{
    function burn(uint256 _id) external ;
}
interface IColorNftV2{
    function mint(address _to) external;
}
contract NodeNFTLock  is Ownable{
using SafeMath for uint256;
struct userLockInfo{
    address user;
    uint256 reward;
    uint256 time;
    uint256 endTime;
    address nft;
}
    address public rewardToken;
    mapping(address => uint256 ) public NFTToReward;
    mapping(uint256 => uint256)  public rewardList;
    mapping(address => userLockInfo[]) public userLockInfos;
    mapping(address => address) public NFTToNFTV2;
    uint256 public day = 86400;
    uint256 public LockTime;
    uint256 public OneBlockTime = 6;
    uint256[] public rewardAmount = [   
        1000000000000000000000,
        6000000000000000000000,
        20000000000000000000000,
        80000000000000000000000,
        240000000000000000000000,
        480000000000000000000000,
        1000000000000000000000000];
    
     
    constructor(address[] memory _nfts, address[] memory _nftsV2){
        LockTime = day.mul(1000);
        for(uint256 i =0 ; i< rewardAmount.length ;i++){
            NFTToReward[_nfts[i]] = rewardAmount[i];
        }
        for(uint256 i = 0 ; i<7; i ++ ){
        NFTToNFTV2[_nfts[i]] = _nftsV2[i];
        }
    }
    function deposit(uint256 _amount) public onlyOwner{
        TransferHelper.safeTransferFrom(rewardToken, msg.sender, address(this), _amount);
    }
    function backToken(uint256 _amount) public onlyOwner{
        TransferHelper.safeTransfer(rewardToken,msg.sender, _amount);
    }
    function Staking(address nft,uint256 _id) public {
        require(NFTToReward[nft] !=0 ,"input error");
        IERC721(nft).transferFrom(msg.sender, address(this), _id);
        IColorNft(nft).burn(_id);
        IColorNftV2(NFTToNFTV2[nft]).mint(msg.sender);
        userLockInfo memory info = userLockInfo({
            user:msg.sender, 
            reward:NFTToReward[nft],
            time:block.timestamp,
            endTime:block.timestamp.add(LockTime),
            nft:nft
        });
        userLockInfos[msg.sender].push(info);
    }
    function getUserLockInfoLength(address _user) public view returns(uint256) {
        return userLockInfos[_user].length;
    }
function CanClaim() public view returns(uint256){
    uint256 total = 0;
       for(uint256 i = 0 ; i <  userLockInfos[msg.sender].length;i++){
            if(userLockInfos[msg.sender][i].reward == 0) {
                continue;
            }
            if(block.timestamp >  userLockInfos[msg.sender][i].time ){
               uint256 OneBlockTimeReward =  NFTToReward[userLockInfos[msg.sender][i].nft].div(LockTime.div(OneBlockTime));
               uint256 reward =  block.timestamp.sub(userLockInfos[msg.sender][i].time).div(OneBlockTime).mul(OneBlockTimeReward);
                total = total.add(reward);  
            }
          
        }
        return total;
}

function Claim() public {
        
        for(uint256 i = 0 ; i <  userLockInfos[msg.sender].length;i++){
            if(userLockInfos[msg.sender][i].reward == 0) {
                continue;
            }
            if(block.timestamp >  userLockInfos[msg.sender][i].time ){
               uint256 OneBlockTimeReward =  NFTToReward[userLockInfos[msg.sender][i].nft].div(LockTime.div(OneBlockTime));
               uint256 reward =  block.timestamp.sub(userLockInfos[msg.sender][i].time).div(OneBlockTime).mul(OneBlockTimeReward);
                userLockInfos[msg.sender][i].time = block.timestamp;
                userLockInfos[msg.sender][i].reward = userLockInfos[msg.sender][i].reward.sub(reward);
               TransferHelper.safeTransfer(rewardToken,msg.sender, reward);
               
            }
          
        }
    }
}