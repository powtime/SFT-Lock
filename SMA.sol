// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SMA {
    uint256 tokenIdCounter;

    uint256[] mintedNFT;

    address immutable CONTRACT_OWNER;

    address public NDASP_ADDRESS;


    mapping (string _channel => mapping (string _location => bool)) isUpload;

    mapping (address _address => uint256[]) nftOfAddress;

    mapping (address _address => bool) isPrimaryUser;


    struct NFSTInfo {
        uint256 tokenId;
        address owner;
        bool isStack;
        bool isReclaim;
        string channel;
        string location;
    }
    mapping (uint256 _tokenId => NFSTInfo) nfstInfo;


    event MINT_NFST(address _from, address _to, uint256 _tokenId);

    event RECLAIM_NFST(address _from, uint256 _tokenId);

    event TRANSFER_NFST(address _from, address _to, uint256 _tokenId);


    modifier OnlyContractOnwer() {
        require(msg.sender == CONTRACT_OWNER, "Only contract owner.");
        _;
    }

    modifier OnlyNDASP() {
        require(msg.sender == NDASP_ADDRESS, "Only NDASP_ADDRESS");
        _;
    }


    constructor() {
        tokenIdCounter = 0;
        CONTRACT_OWNER = msg.sender;
    }


    function mintNFST(address _to, string calldata _channel, string calldata _location) public OnlyContractOnwer {
        require(_to != address(0), "Zero address.");
        require(!isUpload[_channel][_location], "Already upload.");

        uint256 newTokenId = ++tokenIdCounter;

        NFSTInfo storage info = nfstInfo[newTokenId];
        info.tokenId = newTokenId;
        info.owner = _to;
        info.channel = _channel;
        info.location = _location;

        isUpload[_channel][_location] = true;
        mintedNFT.push(newTokenId);
        nftOfAddress[_to].push(newTokenId);

        if (!isPrimaryUser[_to]) {
            isPrimaryUser[_to] = true;
        }

        emit MINT_NFST(address(0), _to, newTokenId);
    }

    function transferNFST(address _from, address _to, uint256 _tokenId) public {
        NFSTInfo storage info = nfstInfo[_tokenId];

        require(!info.isReclaim, "Is reclaimed.");
        require(_from != address(0) && _to != address(0), "Zero address.");
        require(isPrimaryUser[_from] && _from == info.owner, "Not the owner.");

        removeUintFromArray(nftOfAddress[_from], _tokenId);
        if (nftOfAddress[_from].length == 0) {
            isPrimaryUser[_from] = false;
        }

        info.owner = _to;
        isPrimaryUser[_to] = true;
        nftOfAddress[_to].push(_tokenId);

        emit TRANSFER_NFST(_from, _to, _tokenId);
    }

    function reclaimNFST(uint256 _tokenId) public OnlyContractOnwer {
        NFSTInfo storage info = nfstInfo[_tokenId];

        require(CONTRACT_OWNER == info.owner, "Not the contract owner.");

        isUpload[info.channel][info.location] = false;
        removeUintFromArray(mintedNFT, _tokenId);
        removeUintFromArray(nftOfAddress[CONTRACT_OWNER], _tokenId);

        info.isReclaim =true;

        if (nftOfAddress[CONTRACT_OWNER].length == 0) {
            isPrimaryUser[CONTRACT_OWNER] = false;
        }

        emit RECLAIM_NFST(CONTRACT_OWNER, _tokenId);
    }

    function getNFSTInfo(uint256 _tokenId) public view returns (
        uint256 tokenId,
        address owner,
        bool isStack,
        bool isReclaim,
        string memory channel,
        string memory location
    ) {
        NFSTInfo storage info = nfstInfo[_tokenId];

        return (
            info.tokenId,
            info.owner,
            info.isStack,
            info.isReclaim,
            info.channel,
            info.location
        );
    }

    function getNFTOfAddress(address _address) public view returns (uint256[] memory) {
        return nftOfAddress[_address];
    }

    function getMintedNFT() public view returns (uint256[] memory) {
        return mintedNFT;
    }

    function getIsPrimaryUser(address _address) public view returns (bool) {
        return isPrimaryUser[_address];
    }

    function getContractOwner() public view returns (address) {
        return CONTRACT_OWNER;
    }

    function getIsUpload(string calldata _channel, string calldata _location) public view returns (bool) {
        return isUpload[_channel][_location];
    }

    function setNDASP(address _address) public OnlyContractOnwer {
        NDASP_ADDRESS = _address;
    }

    function setStakeInfoOfNFST(uint256 _tokenId, address _owner, bool _isStack) public OnlyNDASP {
        NFSTInfo storage info = nfstInfo[_tokenId];
        info.owner = _owner;
        info.isStack = _isStack;
    }

    function removeUintFromArray(uint[] storage _array, uint _item) private {
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _item) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }

}
