// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/ISMA.sol";
import "./interface/INDASP.sol";

contract PU {
    ISMA SMA;

    address SMA_CONTRAC_ADDRESS;

    INDASP NDASP;

    address NDASP_CONTRAC_ADDRESS;

    address CONTRACT_OWNER;

    uint256 DECIMALS;

    uint256 tokenIdCounterOfRNFST;

    uint256[] mintedRNFST;


    mapping (address _address => uint256[]) rnfstOfAddress;

    mapping (uint256 _tokenIdOfSNFST => uint256 _tokenIdOfRNFST) snfstState;


    struct RNFSTInfo {
        uint256 tokenIdOfRNFST;
        uint256 tokenIdOfSNFST;
        address owner;
        address user;
        bool isRentOut;
        string channel;
        string location;
        uint256 duration;
        uint256 expirationTime;
        uint256 price;
    }
    mapping (uint256 _tokenIdOfRNFST => RNFSTInfo) rnfstInfo;


    event TRANSFER_RNFST(address _from, address _to, uint256 _tokenIdOfRNFST);

    event RENTOUT_RNFST(address _renter, uint256 _tokenIdOfRNFST);

    event TRANSFER(address _sender, address _recipient, address _primaryUser, uint256 _amount);


    modifier OnlyAuthorizedUser() {
        require(SMA.getIsPrimaryUser(msg.sender) && msg.sender == CONTRACT_OWNER, "Only authorized user.");
        _;
    }


    constructor(address _smaContractAddress, address _ndaspContractAddress) {
        CONTRACT_OWNER = msg.sender;
        SMA_CONTRAC_ADDRESS = _smaContractAddress;
        SMA = ISMA(SMA_CONTRAC_ADDRESS);
        NDASP_CONTRAC_ADDRESS = _ndaspContractAddress;
        NDASP = INDASP(NDASP_CONTRAC_ADDRESS);
        DECIMALS = 18;
        tokenIdCounterOfRNFST = 1;
    }

    function mintRNFT(uint256 _tokenIdOfSNFST, uint256 _duration, uint256 _price) public OnlyAuthorizedUser {
        require(snfstState[_tokenIdOfSNFST] == 0, "This SNFT is occupied.");

        ( , , address owner, , , string memory channel, string memory location) = NDASP.getSNFSTInfo(_tokenIdOfSNFST);

        require(msg.sender == owner, "Not the owner of this SNFT.");

        uint256 newTokenId = tokenIdCounterOfRNFST++;

        RNFSTInfo storage info = rnfstInfo[newTokenId];
        info.tokenIdOfRNFST = newTokenId;
        info.tokenIdOfSNFST = _tokenIdOfSNFST;
        info.owner = msg.sender;
        info.channel = channel;
        info.location = location;
        info.duration = _duration;
        info.price = _price;

        mintedRNFST.push(newTokenId);
        rnfstOfAddress[msg.sender].push(newTokenId);
        snfstState[_tokenIdOfSNFST] = newTokenId;

        emit TRANSFER_RNFST(address(0), msg.sender, newTokenId);
    }

    function rentRNFT(uint256 _tokenIdOfRNFST) public payable {
        RNFSTInfo storage info = rnfstInfo[_tokenIdOfRNFST];

        require(info.owner != address(0), "This RNFT is not exist.");
        require(info.user == address(0) && !info.isRentOut, "Already rent out.");
        require(msg.value == info.price, "Invalid value.");
        
        require(receiveETH(), "ETH transfer error.");

        info.user = msg.sender;
        info.isRentOut = true;
        info.expirationTime = block.timestamp + info.duration;

        removeUintFromArray(rnfstOfAddress[info.owner], _tokenIdOfRNFST, false);
        rnfstOfAddress[msg.sender].push(_tokenIdOfRNFST);

        emit RENTOUT_RNFST(msg.sender, _tokenIdOfRNFST);
    }

    function receiveETH() public payable returns (bool) {
        require(msg.value > 0, "No ETH send.");

        return true;
    }
    
    function sendETH(address payable _to, uint256 _amount) private {
        require(address(this).balance >= _amount, "Insufficient contract balance");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function transfer(address _recipient, uint256 _amount) public {
        NDASP.transfer(CONTRACT_OWNER, _recipient, CONTRACT_OWNER, _amount);

        emit TRANSFER(CONTRACT_OWNER, _recipient, CONTRACT_OWNER, _amount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRNFTInfo(uint256 _tokenIdOfRNFST) public view returns (
        uint256 tokenIdOfRNFST,
        uint256 tokenIdOfSNFST,
        address owner,
        address user,
        bool isRentOut,
        string memory channel,
        string memory location,
        uint256 duration,
        uint256 expirationTime,
        uint256 price
    ) {
        RNFSTInfo storage info = rnfstInfo[_tokenIdOfRNFST];

        return (
            info.tokenIdOfRNFST,
            info.tokenIdOfSNFST,
            info.owner,
            info.user,
            info.isRentOut,
            info.channel,
            info.location,
            info.duration,
            info.expirationTime,
            info.price
        );
    }

    function getRNFTOfAddress(address _address) public view returns (uint256[] memory) {
        return rnfstOfAddress[_address];
    }

    function getIsPrimaryUser(address _address) public view returns (bool) {
        return SMA.getIsPrimaryUser(_address);
    }

    function getUserListOfPrimaryUser(address _primaryUser) public view returns (address[] memory) {
        return NDASP.getUserListOfPrimaryUser(_primaryUser);
    }

    function getUserShare(address _primaryUser, address _user) public view returns (uint256) {
        return NDASP.getUserShares(_primaryUser, _user);
    }

    function getSNFSTInfo(uint256 _tokenIdOfSNFST) public view returns (
        uint256 tokenIdOfSNFST,
        uint256 tokenIdOfNFST,
        address owner,
        bool isLock,
        bool isRetrieve,
        string memory channel,
        string memory location
    ) {
        return NDASP.getSNFSTInfo(_tokenIdOfSNFST);
    }

    function getSNFTState(uint256 _tokenIdOfSNFST) public view returns (uint256) {
        return snfstState[_tokenIdOfSNFST];
    }

    function resetSNFTState(uint256 _tokenIdOfSNFST) public OnlyAuthorizedUser {
        require(snfstState[_tokenIdOfSNFST] != 0, "Already reset.");
        require(rnfstInfo[snfstState[_tokenIdOfSNFST]].isRentOut, "Did not rent out.");
        require(rnfstInfo[snfstState[_tokenIdOfSNFST]].expirationTime < block.timestamp, "This SNFT is occupied.");

        snfstState[_tokenIdOfSNFST] = 0;
    }

    function removeUintFromArray(uint[] storage _array, uint _value, bool _isKeepOrder) private {
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _value) {
                if (_isKeepOrder) {
                    for (uint256 j = i; j < _array.length - 1; j++) {
                        _array[j] = _array[j + 1];
                    }
                    _array.pop();
                } else {
                    _array[i] = _array[_array.length - 1];
                    _array.pop();
                }

                break;
            }
        }
    }

}
