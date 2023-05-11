// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Guild is ERC1155,Ownable {

    struct guildInFo{
        string guildName;
        string logo;
        string guildDescribe;
        address guildManager;
    }

    uint256 public guildId;
    address[] public secondaryAdministrators;
    mapping(address => bool) public isnotWhitelistUser; 
    mapping(uint256 =>mapping(address => bool)) public isnotcreater;
    mapping(address => uint256) public userGuildNum;
    mapping(address => mapping(uint256 =>guildInFo[])) public guildInFoOWner;


    guildInFo[] public guildInFos;
    constructor()ERC1155("uri") {
    }
    function getSecondaryAdministratorsLength() public view returns(uint256) {
        return secondaryAdministrators.length;
    }

    function setBatchSecondaryAdministrator(address[] memory users) public onlyOwner{
        for(uint256 i = 0 ; i<users.length; i++){
            require(!isnotWhitelistUser[users[i]],"WhiteList added repeatedly");
            isnotWhitelistUser[users[i]] = true;
            secondaryAdministrators.push(users[i]);
        }
    }
    function deleteBatchSecondaryAdministrator(address[] memory users) public onlyOwner {
        for(uint256 i = 0 ; i < users.length; i ++) {
            require(isnotWhitelistUser[users[i]],"WhiteList added repeatedly");
            isnotWhitelistUser[users[i]] = false;
            deleteWlistArray(users[i]);

        }
    }
    function deleteWlistArray(address _user) internal {
        for(uint256 i = 0 ; i < secondaryAdministrators.length; i++) {
            if(_user == secondaryAdministrators[i]){
                secondaryAdministrators[i] = secondaryAdministrators[secondaryAdministrators.length -1];
                secondaryAdministrators.pop();
            }
        }
    }
    function createGuild(string memory _guildName , string memory _logo,string memory _guildDescribe, address  managers) public {
        require(isnotWhitelistUser[msg.sender] == true , "you not aprove");
        
        _mint(msg.sender ,guildId, 1,"test" );
        guildInFo memory info = guildInFo(_guildName,_logo,_guildDescribe,managers);
        guildInFos.push(info);
        guildInFoOWner[msg.sender][guildId] = guildInFos;
        userGuildNum[msg.sender] = guildId;
        isnotcreater[guildId][msg.sender] =true;
        guildId++;
    }

    function joinGuild(uint256 _guildId) public {
        require(_guildId <= 10 , "guildId is error");
        _mint(msg.sender ,_guildId, 1 , "test");
        userGuildNum[msg.sender] = _guildId;
    }
    function addguildManagers(address  manager) public  {
        require(isnotcreater[userGuildNum[msg.sender]][msg.sender] == true, "you are not manager" );
        guildInFoOWner[msg.sender][userGuildNum[msg.sender]][userGuildNum[msg.sender]].guildManager = manager;
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(from == msg.sender && to == msg.sender, "not to transfer");
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
        require(from == msg.sender && to == msg.sender, "not to transfer");

        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    
}