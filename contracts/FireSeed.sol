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

    using Counters for Counters.Counter;
    string public constant name = "FireSeed";
    string public constant symbol = "FIRESEED";

    uint256 private TOP_FEE_RATIO;
    uint256 private MIDDLE_FEE_RATIO;
    uint256 private DOWN_FEE_RATIO;
    uint256 private TOTAL_REWARD_RATIO_ONE;
    uint256 private TOTAL_REWARD_RATIO_TWO;
    uint256 private TOTAL_MAIN_RATIO;
    uint256 private FEE_RATIO = 100;

    

    Counters.Counter private _idTracker;
    event passFireSeed(address  from, address  to, uint256  tokenId, uint256  amount, uint256  transferTime);
    string public baseURI;
    bool public useITreasuryDistributionContract;
    uint256 public maxMint = 1e6;
    uint256 public fee;
    uint256 public amountOfSbt007;
    uint256 public wListMintMax;
    uint256 public userMintMax;
    uint256 public lowestMint;
    uint256 public whitelistDiscount;
    uint256 public fireSeedDiscount;
    address public feeReceiver;
    address public treasuryDistributionContract;
    address public rainbowTreasury;
    address public weth;
    address public fireSoul;    
    address[] public whiteList;

    mapping(address => bool) public isRecommender;
    mapping(address => address) public recommender;
    mapping(address => address[]) public recommenderInfo;
    mapping(address => bool) public isNotWhiteListUser;
    mapping(address => uint256[]) public ownerOfId; 
    mapping(uint256 => uint256) public discountFactors;

    constructor(address  _feeReceiver, address _weth) ERC1155("https://bafybeiblhsbd5x7rw5ezzr6xoe6u2jpyqexbfbovdao2vj5i3c25vmm7d4.ipfs.nftstorage.link/0.json") {
    _idTracker.increment();

    feeReceiver = _feeReceiver;
    weth = _weth;
    baseURI = "https://bafybeiblhsbd5x7rw5ezzr6xoe6u2jpyqexbfbovdao2vj5i3c25vmm7d4.ipfs.nftstorage.link/";
    wListMintMax = 1000;
    userMintMax = 100;
    lowestMint = 1;
    fee =8e16;
    setDiscountFactor(11, 20, 90);
    setDiscountFactor(21, 30, 80);
    setDiscountFactor(31, 40, 70);
    setDiscountFactor(41, 50, 60);
    setDiscountFactor(51, 100, 50);
    TOP_FEE_RATIO = 70;
    MIDDLE_FEE_RATIO = 20;
    DOWN_FEE_RATIO = 10;
    TOTAL_MAIN_RATIO = 70;
    TOTAL_REWARD_RATIO_ONE = 20;
    TOTAL_REWARD_RATIO_TWO = 10;
    fireSeedDiscount = 100;
}
    //onlyOwner
    function setFireSeedDiscount(uint256 _fireSeedDiscount) public onlyOwner{
        require(_fireSeedDiscount != 0, "FireSeed: invalid address");
        fireSeedDiscount = _fireSeedDiscount;
    }
    function setFireSoul(address _fireSoul) public onlyOwner{
        fireSoul = _fireSoul;
    }
    function setRainbowTreasury(address _rainbowTreasury) public onlyOwner{
        require(_rainbowTreasury != address(0) ,"FireSeed: Invalid address" );
        rainbowTreasury = _rainbowTreasury;
    }

    function setDiscountFactor(uint256 _lowerBound, uint256 _upperBound, uint256 _discountFactor) public onlyOwner {
        require(_lowerBound < _upperBound, "FireSeed: Invalid range");
        discountFactors[_lowerBound] = _discountFactor;
        discountFactors[_upperBound] = _discountFactor;
    }
    function deleteDiscountFactor(uint256 _bound) public onlyOwner {
        delete discountFactors[_bound];
    }


    function setLowestMint(uint256 _amount) public onlyOwner{
        lowestMint = _amount;
    }
    function setUserMintMax(uint256 _amount) public onlyOwner{
        userMintMax = _amount;
    }
    function setWListMax(uint256 _amount) public onlyOwner{
        wListMintMax = _amount;
    }
    function cancelAddressInvitation(address _addr) public onlyOwner{
        isRecommender[_addr] = true;
    }
    function changeFeeReceiver(address payable receiver) external onlyOwner {
      feeReceiver = receiver;
    }
    function setFee(uint256 _fee) public onlyOwner{
      fee = _fee;
   }

    function addWhiteListUser(address[] memory _users) public onlyOwner{
        for(uint256 i = 0; i < _users.length ; i++ ){
            isNotWhiteListUser[_users[i]] = true;
            whiteList.push(_users[i]);
        }
    }

    function removeFromWhiteList(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            require(isNotWhiteListUser[users[i]] == true, "FireSeed: User not in whitelist");
            uint256 indexToRemove = findIndexOf(whiteList, users[i]);
            require(indexToRemove < whiteList.length, "FireSeed: User not in whitelist array");
            removeAtIndex(whiteList, indexToRemove);
            isNotWhiteListUser[users[i]] = false;
        }
    }

    function findIndexOf(address[] memory array, address item) private pure returns (uint256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == item) {
                return i;
            }
        }
        return array.length;
    }

    function removeAtIndex(address[] storage array, uint256 index) private {
        require(index < array.length, "Index out of bounds");
        for (uint256 i = index; i < array.length - 1; i++) {
            array[i] = array[i+1];
        }
        array.pop();
    }

    function setUseTreasuryDistributionContract(bool _set) public onlyOwner{
        useITreasuryDistributionContract = _set;
    }
    function setTreasuryDistributionContract(address _treasuryDistributionContract) public onlyOwner{
        treasuryDistributionContract=_treasuryDistributionContract;
    }

    function mintWithETH(uint256 _amount) external payable {
    require(_idTracker.current() > maxMint, "FireSeed: To reach the maximum number of casting ids");
    require(_amount >= lowestMint, "FireSeed: Below Minting Minimum");
    address _top = recommender[msg.sender];
    address _middle = recommender[_top];
    address _down = recommender[_middle];
    ownerOfId[msg.sender].push(_idTracker.current());

    if (isNotWhiteListUser[msg.sender] && _amount <= wListMintMax) {
        uint256 _wlistFee = _amount * fee * whitelistDiscount / 100;
        require(msg.value == _wlistFee, 'Please send the correct number of ETH');
        TransferHelper.safeTransferFrom(weth, msg.sender, feeReceiver, _wlistFee);
        _mint(msg.sender, _idTracker.current(), _amount, '');
        return;
    }

    require(_amount <= userMintMax, "FireSeed: You have exceeded the maximum purchase limit");

    uint256 _fee = calculateFee(_amount);
    uint256 _mainFee = _fee *  TOTAL_MAIN_RATIO / FEE_RATIO;
    uint256 _referralRewards = _fee * TOTAL_REWARD_RATIO_ONE / FEE_RATIO;
    uint256 _cityNodeReferralRewards = _fee * TOTAL_REWARD_RATIO_TWO / FEE_RATIO;
    if (msg.value == 0) {
        TransferHelper.safeTransferFrom(weth, msg.sender, feeReceiver, _mainFee);
        if(_top != address(0) && _middle != address(0) && _down != address(0)){
            if(IFireSoul(fireSoul).checkFID(_top) && IFireSoul(fireSoul).checkFID(_middle) && IFireSoul(fireSoul).checkFID(_down)){
        TransferHelper.safeTransferFrom(weth, msg.sender, _top, _referralRewards * TOP_FEE_RATIO / FEE_RATIO);
        TransferHelper.safeTransferFrom(weth, msg.sender, _middle, _referralRewards * MIDDLE_FEE_RATIO / FEE_RATIO);
        TransferHelper.safeTransferFrom(weth, msg.sender, _down, _referralRewards * DOWN_FEE_RATIO / FEE_RATIO);
            }else if(IFireSoul(fireSoul).checkFID(_top) && IFireSoul(fireSoul).checkFID(_middle) && !IFireSoul(fireSoul).checkFID(_down)){
        TransferHelper.safeTransferFrom(weth, msg.sender, _top, _referralRewards * TOP_FEE_RATIO/ FEE_RATIO);
        TransferHelper.safeTransferFrom(weth, msg.sender, _middle, _referralRewards * MIDDLE_FEE_RATIO / FEE_RATIO);
        TransferHelper.safeTransferFrom(weth, msg.sender, rainbowTreasury, _referralRewards * DOWN_FEE_RATIO/ FEE_RATIO);
            }else if(IFireSoul(fireSoul).checkFID(_top) && !IFireSoul(fireSoul).checkFID(_middle) && !IFireSoul(fireSoul).checkFID(_down)){
        TransferHelper.safeTransferFrom(weth, msg.sender, _top, _referralRewards * TOP_FEE_RATIO / FEE_RATIO);
        TransferHelper.safeTransferFrom(weth, msg.sender, rainbowTreasury, _referralRewards * (MIDDLE_FEE_RATIO + DOWN_FEE_RATIO) / FEE_RATIO);
            }else {
        TransferHelper.safeTransferFrom(weth, msg.sender, rainbowTreasury, _referralRewards);
            }

        }else if(_top != address(0) && _middle != address(0) && _down == address(0)){
            if(IFireSoul(fireSoul).checkFID(_top) && IFireSoul(fireSoul).checkFID(_middle)){
        TransferHelper.safeTransferFrom(weth, msg.sender, _top, _referralRewards * TOP_FEE_RATIO / FEE_RATIO);
        TransferHelper.safeTransferFrom(weth, msg.sender, _middle, _referralRewards * MIDDLE_FEE_RATIO / FEE_RATIO);
        TransferHelper.safeTransferFrom(weth, msg.sender, rainbowTreasury, _referralRewards * TOP_FEE_RATIO / FEE_RATIO);
            }else if(IFireSoul(fireSoul).checkFID(_top) && !IFireSoul(fireSoul).checkFID(_middle)){
        TransferHelper.safeTransferFrom(weth, msg.sender, _top, _referralRewards * TOP_FEE_RATIO / FEE_RATIO);
        TransferHelper.safeTransferFrom(weth, msg.sender, rainbowTreasury, _referralRewards * (MIDDLE_FEE_RATIO + DOWN_FEE_RATIO) / FEE_RATIO);
            }else {
        TransferHelper.safeTransferFrom(weth, msg.sender, rainbowTreasury, _referralRewards);

            }
   
        }else if(_top != address(0) && _middle == address(0) && _down == address(0)){
            if(IFireSoul(fireSoul).checkFID(_top)){
            TransferHelper.safeTransferFrom(weth, msg.sender, _top, _referralRewards * TOP_FEE_RATIO / FEE_RATIO);
        TransferHelper.safeTransferFrom(weth, msg.sender, rainbowTreasury, _referralRewards * (MIDDLE_FEE_RATIO + DOWN_FEE_RATIO) / FEE_RATIO);
            }else {
            TransferHelper.safeTransferFrom(weth, msg.sender, rainbowTreasury, _referralRewards);

            }
   
        }else{
        TransferHelper.safeTransferFrom(weth, msg.sender, rainbowTreasury, _referralRewards);
        }
    } else {
        require(msg.value == _fee, 'Please send the correct number of ETH');
        IWETH(weth).deposit{value: _fee}();
        IWETH(weth).transfer(feeReceiver, _mainFee);
        if(_top != address(0) && _middle != address(0) && _down != address(0)){
            if(IFireSoul(fireSoul).checkFID(_top) && IFireSoul(fireSoul).checkFID(_middle) && IFireSoul(fireSoul).checkFID(_down)){

        IWETH(weth).transfer(_top, _referralRewards * TOP_FEE_RATIO /FEE_RATIO);
        IWETH(weth).transfer(_middle, _referralRewards * MIDDLE_FEE_RATIO / FEE_RATIO);
        IWETH(weth).transfer(_down, _referralRewards * DOWN_FEE_RATIO / FEE_RATIO);
                       }else if(IFireSoul(fireSoul).checkFID(_top) && IFireSoul(fireSoul).checkFID(_middle) && !IFireSoul(fireSoul).checkFID(_down)){
                               IWETH(weth).transfer(_top, _referralRewards * TOP_FEE_RATIO /FEE_RATIO);
        IWETH(weth).transfer(_middle, _referralRewards * MIDDLE_FEE_RATIO / FEE_RATIO);
        IWETH(weth).transfer(rainbowTreasury, _referralRewards * DOWN_FEE_RATIO / FEE_RATIO);
                                             }else if(IFireSoul(fireSoul).checkFID(_top) && !IFireSoul(fireSoul).checkFID(_middle) && !IFireSoul(fireSoul).checkFID(_down)){
    IWETH(weth).transfer(_top, _referralRewards * TOP_FEE_RATIO /FEE_RATIO);
        IWETH(weth).transfer(rainbowTreasury, _referralRewards * MIDDLE_FEE_RATIO / FEE_RATIO);
                                             }else {
        IWETH(weth).transfer(rainbowTreasury, _referralRewards );

                                             }
        }else if(_top != address(0) && _middle != address(0) && _down == address(0)){
            if(IFireSoul(fireSoul).checkFID(_top) && IFireSoul(fireSoul).checkFID(_middle)){
        IWETH(weth).transfer(_top, _referralRewards * TOP_FEE_RATIO /FEE_RATIO);
        IWETH(weth).transfer(_middle, _referralRewards * MIDDLE_FEE_RATIO / FEE_RATIO);
        IWETH(weth).transfer(rainbowTreasury, _referralRewards * DOWN_FEE_RATIO/ FEE_RATIO);
            }else if(IFireSoul(fireSoul).checkFID(_top) && !IFireSoul(fireSoul).checkFID(_middle)){
                IWETH(weth).transfer(_top, _referralRewards * TOP_FEE_RATIO / FEE_RATIO);
                IWETH(weth).transfer(rainbowTreasury ,_referralRewards * (MIDDLE_FEE_RATIO + DOWN_FEE_RATIO)/FEE_RATIO);
            }else {
                IWETH(weth).transfer(rainbowTreasury, _referralRewards);
            }
      
   
        }else if(_top != address(0) && _middle == address(0) && _down == address(0)){
            if(IFireSoul(fireSoul).checkFID(_top)){
        IWETH(weth).transfer(_top, _referralRewards * TOP_FEE_RATIO /FEE_RATIO);
        IWETH(weth).transfer(rainbowTreasury, _referralRewards * (MIDDLE_FEE_RATIO + DOWN_FEE_RATIO)/ FEE_RATIO);
            }else {
        IWETH(weth).transfer(rainbowTreasury, _referralRewards);

            }
      
        }else{
        TransferHelper.safeTransferFrom(weth, msg.sender, rainbowTreasury, _referralRewards);
        }
    }

    if (useITreasuryDistributionContract) {
        ITreasuryDistributionContract(treasuryDistributionContract).setSourceOfIncome(0, 0, _fee);
    }

    _mint(msg.sender, _idTracker.current(), _amount, '');
    _idTracker.increment();
}


function calculateFee(uint256 _amount) internal view returns (uint256) {
    uint256 calculatedFee = _amount * fee * fireSeedDiscount / FEE_RATIO;
    uint256 discountFactor = 100; 
    for (uint256 i = 0; i < _amount; i++) {
        if (discountFactors[i] > 0) {
            discountFactor = discountFactors[i];
        }
    }
    calculatedFee = calculatedFee * discountFactor / 100;
    return calculatedFee;
}
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
