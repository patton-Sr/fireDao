// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./lib/TransferHelper.sol";
import "./interface/ISbt003.sol";
import "./interface/IFireSeed.sol";
import "./interface/IWETH.sol";
import "./FireSeed.sol";

contract FireSoul is ERC721,Ownable{
    FireSeed fireseed;
    string public baseURI;
    string public baseExtension = ".json";
    address public FireSeedAddress;
    address public FLAME;
    uint256 public FID;
    address[] public sbtAddress;
    address public firePassport;
    bool public status;
    bool public feeOn;
    uint256 public fee;
    address public weth;
    address public feeReceiver;
    address public pauseControlAddress;
    address[] public sbt;
    uint[] public  coefficient;
    address public sbt003;
    address[] public UserHaveFID;

    mapping(address => uint256) public UserFID;
    mapping(address => bool) public haveFID;
    mapping(address => uint256[]) public sbtTokenAmount; 
    mapping(address => address) public UserToSoul;
       //set fireSeed, BaseUri, sbt003
    constructor(FireSeed _fireseed, address _firePassport,address _sbt003,address _weth) ERC721("FireSoul", "FireSoul"){
    fireseed = _fireseed;
    firePassport = _firePassport;
	sbt003 = _sbt003;
    weth = _weth;
    baseURI = "https://bafybeib3vsuxwnz53m3n7msi5fwbbeu2iqvz7srgmuf7zedmadppg6evx4.ipfs.nftstorage.link/";
}
    //onlyOwner
    function setSbt003Address(address _sbt003) public onlyOwner{
	    sbt003 = _sbt003;
}
    function setWeth(address _weth) public onlyOwner{
        weth = _weth;
    }
    function setPauseControlAddress(address _pauseControlAddress) public onlyOwner {
    pauseControlAddress = _pauseControlAddress;
}
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
}
    function setFeeStatus() public onlyOwner{
        feeOn = !feeOn;
    }
    function setFeeReceiver(address _to) public onlyOwner{
        feeReceiver = _to;
    }
    function setFee(uint256 _fee) public onlyOwner{
        fee = _fee;
    }

    //main
    function setStatus() external {
           require(msg.sender == pauseControlAddress,"address is error");
           status = !status;
       }
    function checkFID(address user) external view returns(bool){
           return haveFID[user];
       }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
        : "";
  }
  
 

    function burnToMint(uint256 _tokenId) external payable {
        require(!status, "status is error");
        require(haveFID[msg.sender] == false, "you already have FID");
        require(IERC721(firePassport).balanceOf(msg.sender) != 0 ,"you haven't passport");

        address down = IFireSeed(FireSeedAddress).upclass(msg.sender);
        address middle = IFireSeed(FireSeedAddress).upclass(down);
        address superior = IFireSeed(FireSeedAddress).upclass(middle);
        
        if(feeOn){
            
        uint256 feeReceiverAmount = fee / 10 * 9;
        uint256 downAmount = fee / 100 * 5;
        uint256 middleAmount = fee / 100 * 3;
        uint256 superiorAmount = fee / 100 * 2;
        
          if(msg.value == 0) {
              if(down != address(0) && middle != address(0) && superior != address(0)){
              TransferHelper.safeTransferFrom(weth,msg.sender,feeReceiver,feeReceiverAmount);
              TransferHelper.safeTransferFrom(weth,msg.sender,down,downAmount);
              TransferHelper.safeTransferFrom(weth,msg.sender,middle,middleAmount);
              TransferHelper.safeTransferFrom(weth,msg.sender,superior,superiorAmount);
              } else{
              TransferHelper.safeTransferFrom(weth,msg.sender,feeReceiver,fee);
              }
          } else {
              require(msg.value == fee,"provide the error number on ETH");
              IWETH(weth).deposit{value: fee}();
              if(down != address(0) && middle != address(0) && superior != address(0)){
              IWETH(weth).transfer(feeReceiver,feeReceiverAmount);
              IWETH(weth).transfer(down,downAmount);
              IWETH(weth).transfer(middle,middleAmount);
              IWETH(weth).transfer(superior,superiorAmount);
              }else{
              IWETH(weth).transfer(feeReceiver,fee);
              }

          }
      }
        fireseed.burnFireSeed(msg.sender,_tokenId ,1);
        _mint(msg.sender, FID);
        UserHaveFID.push(msg.sender);
        UserFID[msg.sender] = FID;
        haveFID[msg.sender] = true;
        address _Soul = address(new Soul(msg.sender , address(this)));
        UserToSoul[msg.sender] = _Soul;
        if(UserToSoul[superior] != address(0) && UserToSoul[middle] != address(0) && UserToSoul[down] != address(0)){
        ISbt003(sbt003).mint(UserToSoul[down], 7*10**18);
        ISbt003(sbt003).mint(UserToSoul[middle],2*10**18);
        ISbt003(sbt003).mint(UserToSoul[superior], 10**18);
        }
        FID++;
    }
    function getUserHaveFIDLength() public view returns(uint256) {
        return UserHaveFID.length;
    }
    function getSoulAccount(address _user) external view returns(address){
        return UserToSoul[_user];
    }
    function setFlameAddress(address _FLAME) public onlyOwner{
        FLAME = _FLAME;
    }

    function setFireSeedAddress(address _FireSeedAddress) public onlyOwner{
            FireSeedAddress = _FireSeedAddress;
    }
    function checkFIDA(address _user) external view returns(uint256) {
        return  UserFID[_user];
    }
      /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(from == msg.sender && to == msg.sender ,"the FID not to transfer others" );
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(from == msg.sender && to == msg.sender ,"the FID not to transfer others" );
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(from == msg.sender && to == msg.sender ,"the FID not to transfer others" );
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }
}

contract Soul {
    address public owner;
    address public create;
    constructor(address _owner, address _create) {
        owner = _owner;
        create = _create;
    }
}
