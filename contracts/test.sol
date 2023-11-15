pragma solidity =0.8.18;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

interface IRainbowNft{
     function mint(address _to) external;
}
contract test{
    address public usdt;
    mapping(uint256 => address) public _nft;
    function set(uint256 _i, address _addr)public {
        _nft[_i] = _addr;
    }
    function setUsdt(address _addr) public {
        usdt = _addr;
    }
    function _mint(uint256 _i) public {
        IRainbowNft(_nft[_i]).mint(msg.sender);
    }
    function transfer(address _addr,uint256 _amount)public {
        TransferHelper.safeTransferFrom(usdt,msg.sender,_addr,_amount);
    }
    function transfer2(address _addr, uint256 _amount) public {
        IERC20(usdt).transferFrom(msg.sender, _addr, _amount);
    }
}