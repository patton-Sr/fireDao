// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CityNodeTreasury.sol";
import "./interface/IFireSoul.sol";
import "./interface/IReputation.sol";
import "./interface/ICityNodeTreasury.sol";
import "./interface/IWETH.sol";
import "./lib/TransferHelper.sol";


contract cityNode is ERC1155, Ownable {

    struct cityNodeInfo{
        uint256 NodeId;
        string  NodeName;
        address NodeOwner;
        uint256 createTime;
        uint256 joinCityNodeTime;
        address Treasury;
    }
 
    address public weth;
    bool public contractStatus; 
    address public fdTokenAddress;
    uint256 public ctiyNodeId;
    address public pauseAddress;
    address public fireSeed;
    address public fireSoul;
    address public Reputation;
    uint256 public proportion;
    mapping(address => bool) public isNotCityNodeUser;
    mapping(uint256 => bool) public isNotLightCity;
    mapping(address => bool) public cityNodeCreater;
    mapping(uint256 => address[]) public cityNodeMember;
    mapping(address => uint256) public cityNodeUserNum;
    mapping(uint256 => uint256) public cityNodeIncomeAmount;
    mapping(address => cityNodeInfo) public userInNodeInfo;
    mapping(address => uint256) public userTax;
    mapping(uint256 => address) public cityNodeAdmin;
    mapping(address => address) public nodeTreasuryAdmin;
    cityNodeInfo[] public cityNodeInfos;

    constructor(address _weth) ERC1155("test") {
        proportion = 5;
        weth = _weth;
    }
    
    //external
    function isNotCityNodeLight(address _user) external view returns(bool){
        return isNotLightCity[cityNodeUserNum[_user]];
    }
    function cityNodeIncome(address _user, uint256 _income) external {
        require(msg.sender == fireSeed,"CityNode: invalid call");
        cityNodeIncomeAmount[cityNodeUserNum[_user]] += _income;
    }
    function getUserInNodeInfo(address _nodeUser) external view returns(cityNodeInfo memory) {
        return userInNodeInfo[_nodeUser];
    }

    function getIsCityNode(address account, uint256 fee) external payable  {
    require(msg.sender == fdTokenAddress, "callback error");
    require(isNotCityNodeUser[account],"callback error");
    // Calculate admin fee and node treasury fee
    uint256 adminFee = fee * proportion / 10;
    uint256 nodeTreasuryFee = fee * (10 - proportion) / 10;

    // Get admin address and node treasury address
    address admin = cityNodeAdmin[cityNodeUserNum[account]];
    address nodeTreasury = nodeTreasuryAdmin[account];

    if(msg.value == 0) {
        // Transfer WETH tokens to admin and node treasury
        TransferHelper.safeTransferFrom(weth, account, admin, adminFee);
        TransferHelper.safeTransferFrom(weth, account, nodeTreasury, nodeTreasuryFee);
    } else {
        // Deposit ETH into WETH and transfer WETH tokens to admin and node treasury
        require(msg.value == fee, "Invalid ETH value");
        IWETH(weth).deposit{value: fee}();
        IWETH(weth).transfer(admin, adminFee);
        IWETH(weth).transfer(nodeTreasury, nodeTreasuryFee);
    }

    // Update user tax
    userTax[account] += fee;

}

 
    function getCityNodeReputation(uint256 cityNodeNum) public view returns(uint256){
        uint256 CityNodeReputation;
        for(uint i = 0 ; i < cityNodeMember[cityNodeNum].length ; i++){
            CityNodeReputation += IReputation(Reputation).checkReputation(cityNodeMember[cityNodeNum][i]);
        }
        return CityNodeReputation;
    }
    function setPause() external  {
        require(msg.sender == pauseAddress,"callback address is not pauseAddress");
        contractStatus = !contractStatus;   
    }
    //onlyOwner
    function setProportion(uint256 _proportion) public onlyOwner {
        proportion = _proportion;
    }
    function setFdTokenAddress(address _fdTokenAddress) public onlyOwner{
        fdTokenAddress = _fdTokenAddress;
    }
    function setReputationAddress(address _Reputation) public onlyOwner{
        Reputation = _Reputation;
    }
    function setFireSoulAddress(address _fireSoul) public onlyOwner{
        fireSoul = _fireSoul;
    }

    function setPause(address _pauseAddress) public onlyOwner{
        pauseAddress = _pauseAddress;
    }
    //view
    function isNotCityNodeUsers(address _user) external view returns(bool){
        return isNotCityNodeUser[_user];
    }
    function getCityNodeLength() public view returns(uint256){ 
        return cityNodeInfos.length;
    }
    function checkCityNodeId() public view returns(uint256) {
        return cityNodeUserNum[msg.sender];
    }

    //main
    function createCityNode(string memory cityNodeName) public {
    require(!contractStatus, "Contract status is false");
    require(IFireSoul(fireSoul).checkFID(msg.sender), "You haven't FID, please burn fireseed to create"); 
    require(IReputation(Reputation).checkReputation(msg.sender) > 100000*10*18,"not enough");

    // Create a new CityNodeTreasury contract and transfer ownership to the creator.
    CityNodeTreasury nodeTreasury = new CityNodeTreasury(payable(msg.sender), address(this));

    // Mint a new NFT with the current user as the owner.
    uint256 tokenId = ctiyNodeId;
    _mint(msg.sender, tokenId, 1, "test");

    // Update the city node data structures.
    cityNodeCreater[msg.sender] = true;
    cityNodeMember[tokenId].push(msg.sender);
    cityNodeUserNum[msg.sender] = tokenId;
    cityNodeAdmin[tokenId] = msg.sender;
    nodeTreasuryAdmin[msg.sender] = address(nodeTreasury);
    cityNodeInfo memory info = cityNodeInfo(tokenId, cityNodeName, msg.sender, block.timestamp, block.timestamp, address(nodeTreasury));
    cityNodeInfos.push(info);
    userInNodeInfo[msg.sender] = info;
    ctiyNodeId++;
}


 function joinCityNode(uint256 cityNodeNum) public {
    require(!contractStatus,"Status is false");
    require(IFireSoul(fireSoul).checkFID(msg.sender) , "you haven't FID,plz burn fireseed to create"); 
    require(!cityNodeCreater[msg.sender], "you are already a creator");
    require(!isNotCityNodeUser[msg.sender], "you are already join a cityNode");
    require(cityNodeNum < ctiyNodeId, "you input error");
    
    cityNodeMember[cityNodeNum].push(msg.sender);
    cityNodeUserNum[msg.sender] = cityNodeNum;
    
    string memory cityName = userInNodeInfo[cityNodeAdmin[cityNodeNum]].NodeName;
    uint256 createTime = userInNodeInfo[cityNodeAdmin[cityNodeNum]].createTime;
    address nodeAdmin = cityNodeAdmin[cityNodeNum];
    address nodeTreasury = nodeTreasuryAdmin[nodeAdmin];

    cityNodeInfo memory Info = cityNodeInfo(
        cityNodeNum,
        cityName,
        nodeAdmin,
        createTime,
        block.timestamp,
        nodeTreasury
    );
    cityNodeInfos.push(Info);

    _mint(msg.sender, cityNodeNum, 1, "test");

    userInNodeInfo[msg.sender] = Info;  
    isNotCityNodeUser[msg.sender] = true;
}

function changeNodeAdmin(address newAdmin) public {
    require(!contractStatus, "Contract status is false");
    require(IFireSoul(fireSoul).checkFID(msg.sender), "You don't have FID, please burn fireseed to create");
    require(cityNodeCreater[msg.sender], "You are not a creator");
    uint256 nodeNum = cityNodeUserNum[msg.sender];
    require(cityNodeUserNum[newAdmin] == nodeNum, "The address does not belong to your city node");

    cityNodeAdmin[nodeNum] = newAdmin;
    cityNodeCreater[newAdmin] = true;
    nodeTreasuryAdmin[newAdmin] = nodeTreasuryAdmin[msg.sender];
    ICityNodeTreasury(nodeTreasuryAdmin[msg.sender]).transferOwner(msg.sender, payable(newAdmin));
}

    function deleteCityNodeUser(address _nodeUser) public {
    require(!contractStatus, "Contract is inactive");
    require(cityNodeCreater[msg.sender], "You are not a creator");
    require(cityNodeAdmin[cityNodeUserNum[msg.sender]] != address(0), "Admin address is invalid");

    uint256 nodeNum = cityNodeUserNum[msg.sender];
    require(msg.sender == cityNodeAdmin[nodeNum], "You are not node admin");

    _burn(_nodeUser, nodeNum, 1);
    isNotCityNodeUser[_nodeUser] = false;
}

    function quitCityNode() public{
        require(!contractStatus,"Status is false");
        require(!isNotCityNodeUser[msg.sender],"you haven't join any citynode");
        

        _burn(msg.sender,cityNodeUserNum[msg.sender],1);
        
        isNotCityNodeUser[msg.sender] = false;
    }


    function lightCityNode() public {
        require(!contractStatus,"Status is false");
        if(getCityNodeReputation(cityNodeUserNum[msg.sender]) >= 1000000 *10**18){
            isNotLightCity[cityNodeUserNum[msg.sender]] = true;
        }
    }

      function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(false, "not to transfer");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }
    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(false, "not to transfer");

        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}