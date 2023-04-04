// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./interface/ITreasuryDistributionContract.sol";
import "./interface/ISbt007.sol";
import "./interface/IFireSoul.sol";
import "./lib/TransferHelper.sol";
import "./interface/IWETH.sol";

contract FireSeed is ERC1155 ,DefaultOperatorFilterer, Ownable{

    string public constant name = "FireSeed";
    string public constant symbol = "FIRESEED";

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;
    event passFireSeed(address  from, address  to, uint256  tokenId, uint256  amount, uint256  transferTime);
    bool public FeeStatus;
    string public baseURI;
    bool public useITreasuryDistributionContract;
    address  public feeReceiver;
    address public treasuryDistributionContract;
    address public weth;
    address public Sbt007;
    address public fireSoul;
    uint256 public fee;
    uint256 public amountOfSbt007;
    mapping(address => bool) public isRecommender;
    mapping(address => address) public recommender;
    mapping(address => address[]) public recommenderInfo;
    mapping(address => bool) public WhiteList;
    mapping(address => uint256[]) public ownerOfId; 

    constructor(address _Sbt007,address  _feeReceiver, address _weth) ERC1155("https://bafybeiblhsbd5x7rw5ezzr6xoe6u2jpyqexbfbovdao2vj5i3c25vmm7d4.ipfs.nftstorage.link/0.json") {
    _idTracker.increment();
    setSbt007(_Sbt007);
    setAmountOfSbt007(10);
    feeReceiver = _feeReceiver;
    weth = _weth;
    baseURI = "https://bafybeiblhsbd5x7rw5ezzr6xoe6u2jpyqexbfbovdao2vj5i3c25vmm7d4.ipfs.nftstorage.link/";
}
    //onlyOwner
    function cancelAddressInvitation(address _addr) public onlyOwner{
        isRecommender[_addr] = true;
    }
    function setSbt007(address _Sbt007) public onlyOwner{
        Sbt007 = _Sbt007;
    }
    function setAmountOfSbt007(uint256 _amountOfSbt007) public onlyOwner{
        amountOfSbt007 = _amountOfSbt007;
    }
    function changeFeeReceiver(address payable receiver) external onlyOwner {
      feeReceiver = receiver;
    }
    function setFee(uint256 fees) public onlyOwner{
      fee = fees;
   }
    function setFeeStatus() public onlyOwner{
      FeeStatus = !FeeStatus;
   }
    function setWhiteListUser(address _user) public onlyOwner{
        WhiteList[_user] = true;
    }
    function delWhiteListUser(address _user) public onlyOwner{
        WhiteList[_user] = false;
    }
    function setFireSoul(address _fireSoul) public onlyOwner {
        fireSoul = _fireSoul;
    }
    function setUseTreasuryDistributionContract(bool _set) public onlyOwner{
        useITreasuryDistributionContract = _set;
    }
    function setTreasuryDistributionContract(address _treasuryDistributionContract) public onlyOwner{
        treasuryDistributionContract=_treasuryDistributionContract;
    }

    function mintWithETH(uint256 amount) external payable {
    // 将ownerOfId[msg.sender].push(_idTracker.current())放在函数开头
    ownerOfId[msg.sender].push(_idTracker.current());

    // 不需要计算手续费的情况可以提前返回，减少条件判断的层数
    if (!FeeStatus) {
        _mint(msg.sender, _idTracker.current(), amount, '');
        return;
    }

    // 对于使用白名单的情况，可以提前判断，减少条件判断的层数
    if (WhiteList[msg.sender] && amount <= 1000) {
        _mint(msg.sender, _idTracker.current(), amount, '');
        return;
    }

    uint256 _fee = calculateFee(amount);
    if (msg.value == 0) {
        TransferHelper.safeTransferFrom(weth, msg.sender, feeReceiver, _fee);
    } else {
        require(msg.value == _fee, 'Please send the correct number of ETH');
        IWETH(weth).deposit{value: _fee}();
        IWETH(weth).transfer(feeReceiver, _fee);
    }

    // 对于使用ITreasuryDistributionContract的情况，可以提前判断，减少条件判断的层数
    if (useITreasuryDistributionContract) {
        ITreasuryDistributionContract(treasuryDistributionContract).setSourceOfIncome(0, 0, _fee);
    }

    _mint(msg.sender, _idTracker.current(), amount, '');

    if (IFireSoul(fireSoul).checkFID(msg.sender)) {
        ISbt007(Sbt007).mint(IFireSoul(fireSoul).getSoulAccount(msg.sender), amount * amountOfSbt007 * 10 ** 18);
    }

    _idTracker.increment();
}

function calculateFee(uint256 amount) internal view returns (uint256) {
    if (amount > 50 && amount <= 100) {
        return amount * fee / 2;
    } else if (amount < 50 && amount > 40) {
        return amount * fee * 6 / 10;
    } else if (amount > 30 && amount < 40) {
        return amount * fee * 7 / 10;
    } else if (amount > 20 && amount < 30) {
        return amount * fee * 8 / 10;
    } else if (amount > 10 && amount < 20) {
        return amount * fee * 9 / 10;
    } else {
        return amount * fee;
    }
}
    //view
    function getSingleAwardSbt007() external view returns(uint256) {
        return amountOfSbt007;
    }

    function recommenderNumber(address account) external view returns (uint256) {
        return recommenderInfo[account].length;
    }

    function upclass(address usr) external view returns(address) {
        return recommender[usr];
    }
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }
    function uri(uint256 _tokenId) override public view  returns(string memory) {
        return string(
            abi.encodePacked(
                baseURI,
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }

    function getOwnerIdlength() public view returns(uint256){
        return ownerOfId[msg.sender].length;
    }
    
    function getBalance() public view returns(uint256){
      return address(this).balance;
  }

    /// @notice Mint several tokens at once
    /// @param to the recipient of the token
    /// @param ids array of ids of the token types to mint
    /// @param amounts array of amount to mint for each token type
    /// @param royaltyRecipients an array of recipients for royalties (if royaltyValues[i] > 0)
    /// @param royaltyValues an array of royalties asked for (EIP2981)
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        address[] memory royaltyRecipients,
        uint256[] memory royaltyValues
    ) external {
        require(msg.sender == owner() );
        require(
            ids.length == royaltyRecipients.length &&
                ids.length == royaltyValues.length,
            'ERC1155: Arrays length mismatch'
        );
        _mintBatch(to, ids, amounts, '');
    }
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {   
            require(from != address(0));
            require(to != address(0));

         if (recommender[to] == address(0) &&  recommender[from] != to && !isRecommender[to]) {
             recommender[to] = from;
             recommenderInfo[from].push(to);
             isRecommender[to] = true;
             emit passFireSeed(from, to, tokenId, amount, block.timestamp);
         }
       for(uint i = 0; i < ownerOfId[from].length; i ++ ){
	       if(tokenId == ownerOfId[from][i] && amount == super.balanceOf(msg.sender, tokenId)){
		       uint  _id = i;
                ownerOfId[from][_id] = ownerOfId[from][ownerOfId[from].length - 1];
                ownerOfId[from].pop();
		       break;
	       }
       }
        ownerOfId[to].push(tokenId);

        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
            require(from != address(0));
            require(to != address(0));
         if (recommender[to] == address(0) &&  recommender[from] != to && !isRecommender[to]) {
             recommender[to] = from;
             recommenderInfo[from].push(to);
             isRecommender[to] = true;
         }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    function burnFireSeed(address _account, uint256 _idOfUser, uint256 _value) public  {
        _burn(_account,_idOfUser,_value);
    }
    receive() external payable {}
}
