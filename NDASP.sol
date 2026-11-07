// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interface/ISMA.sol";

contract NDASP {
    ISMA SMA;

    address immutable SMA_CONTRACT_ADDRESS;

    address immutable CONTRACT_OWNER;

    uint256 DECIMALS;

    uint256 tokenIdCounter;

    uint256[] mintedSNFST;

    uint256[] retrievedSNFST;

    uint256 totalSupplyOfSNFST;

    uint256 totalSupplyOfSFST;


    mapping (address _address => uint256[]) snfstOfAddress;

    mapping (address _address => uint256) sfstBalance;

    mapping (address _user => address[]) userListOfPrimaryUser;

    mapping (address _primaryUser => mapping (address _user => bool)) isUserOfPrimaryUser;

    mapping (address _primaryUser => mapping (address _user => uint256)) userShares;

    mapping (uint256 _tokenIdOfNFST => address) originOwnerOfNFST;

    mapping (address _primaryUser => uint256[]) lockedSNFSTOfAddress;

    mapping (address _primaryUser => uint256[]) snfstLockOrder; // 储存主用户自定义的SNFST锁定顺序

    mapping (address _primaryUser => uint256[]) unlockedSNFSTOfAddress;

    mapping (address _primaryUser => uint256[]) snfstUnlockOrder;


    struct SNFSTInfo {
        uint256 tokenIdOfSNFST;
        uint256 tokenIdOfNFST;
        address owner;
        bool isLock;
        bool isRetrieve;
        string channel;
        string location;
    }
    mapping (uint256 _tokenId => SNFSTInfo) snfstInfo;


    event TRANSFER_SNFST(address _from, address _to, uint256 _tokenId);

    event BRUN_SNFST(address _from, uint256 _tokenIdOfSNFST);

    event TRANDFER_SFST(address _from, address _to, address _primaryUser, uint256 _amount);

    event STAKE_NFST(address _from, uint256 _tokenId);

    event RETRIEVE_NFST(address _primaryUser, uint256 _tokenId);

    event LOCK_SNFST(address _primaryUser, uint256 _tokenId);

    event UNLOCK_SNFST(address _primaryUser, uint256 _tokenId);

    event TRANSFER(address _sender, address _recipient, uint256 _amount);


    modifier OnlyContractOwner() {
        require(msg.sender == CONTRACT_OWNER, "Only contract owner.");
        _;
    }

    modifier OnlyPrimaryUser() {
        require(SMA.getIsPrimaryUser(msg.sender), "Only primary user.");
        _;
    }


    constructor(address _smaContractAddress) {
        SMA_CONTRACT_ADDRESS = _smaContractAddress;
        SMA = ISMA(SMA_CONTRACT_ADDRESS);
        CONTRACT_OWNER = msg.sender;
        tokenIdCounter = 0;
        DECIMALS = 18;
    }

    function kycVerify() public pure returns (bool) {
        return true;
    }

    function stakeNFST(address _primaryUser, uint256 _tokenIdOfNFST) public OnlyContractOwner {
        require(kycVerify(), "Invalid KYC proof.");

        ( , address owner, , , string memory channel, string memory location) = SMA.getNFSTInfo(_tokenIdOfNFST);

        require(_primaryUser == owner, "Only the owner can stack NFST.");

        originOwnerOfNFST[_tokenIdOfNFST] = _primaryUser;

        SMA.setStakeInfoOfNFST(_tokenIdOfNFST, address(this), true);

        mintSNFST(_primaryUser, _tokenIdOfNFST, channel, location);

        mintSFST(_primaryUser);

        emit STAKE_NFST(_primaryUser, _tokenIdOfNFST);
    }

    function retrieve(uint256 _tokenIdOfSNFST) public OnlyPrimaryUser {
        SNFSTInfo storage info = snfstInfo[_tokenIdOfSNFST];
        uint256 amount = 1 * 10 ** DECIMALS;

        require(msg.sender == originOwnerOfNFST[info.tokenIdOfNFST], "Not the owner.");
        require(userShares[msg.sender][msg.sender] >= amount, "Shares not enough.");
        require(!info.isLock, "SNFST is locked.");
        require(!info.isRetrieve, "Already retrieved.");

        info.isRetrieve = true;

        sfstBalance[msg.sender] = sfstBalance[msg.sender] - amount;
        userShares[msg.sender][msg.sender] = userShares[msg.sender][msg.sender] - amount;
        totalSupplyOfSFST = totalSupplyOfSFST - amount;

        removeUintFromArray(mintedSNFST, _tokenIdOfSNFST, false);
        removeUintFromArray(snfstOfAddress[msg.sender], _tokenIdOfSNFST, false);

        removeUintFromArray(unlockedSNFSTOfAddress[msg.sender], _tokenIdOfSNFST, false);
        removeUintFromArray(lockedSNFSTOfAddress[msg.sender], _tokenIdOfSNFST, false);
        removeUintFromArray(snfstLockOrder[msg.sender], _tokenIdOfSNFST, true);
        removeUintFromArray(snfstUnlockOrder[msg.sender], _tokenIdOfSNFST, true);

        totalSupplyOfSNFST = totalSupplyOfSNFST - 1;
        retrievedSNFST.push(_tokenIdOfSNFST);

        SMA.setStakeInfoOfNFST(info.tokenIdOfNFST, msg.sender, false);

        emit RETRIEVE_NFST(msg.sender, _tokenIdOfSNFST);
    }

    function mintSNFST(address _to, uint256 _tokenIdOfNFT, string memory _channel, string memory _location) public OnlyContractOwner {
        require(_to != address(0), "Zero address.");
        require(SMA.getIsUpload(_channel, _location), "Did not upload.");

        uint256 newTokenId = ++tokenIdCounter;

        SNFSTInfo storage info = snfstInfo[newTokenId];
        info.tokenIdOfSNFST = newTokenId;
        info.tokenIdOfNFST = _tokenIdOfNFT;
        info.owner = _to;
        info.channel = _channel;
        info.location = _location;

        mintedSNFST.push(newTokenId);
        snfstOfAddress[_to].push(newTokenId);
        unlockedSNFSTOfAddress[_to].push(newTokenId);

        totalSupplyOfSNFST = totalSupplyOfSNFST + 1;

        emit TRANSFER_SNFST(address(0), _to, newTokenId);
    }

    function burnSNFST(address _from, uint256 _tokenIdOfSNFST, string memory _channel, string memory _location) public OnlyContractOwner {
        require(_from != address(0), "Zero address.");
        require(SMA.getIsUpload(_channel, _location), "Did not upload.");

        SNFSTInfo storage info = snfstInfo[_tokenIdOfSNFST];
        info.tokenIdOfSNFST = 0;
        info.tokenIdOfNFST = 0;
        info.owner = address(0);
        info.channel = "";
        info.location = "";

        removeUintFromArray(mintedSNFST, _tokenIdOfSNFST, true);
        removeUintFromArray(snfstOfAddress[_from], _tokenIdOfSNFST, true);
        removeUintFromArray(unlockedSNFSTOfAddress[_from], _tokenIdOfSNFST, true);

        totalSupplyOfSNFST = totalSupplyOfSNFST - 1;

        emit BRUN_SNFST(_from, _tokenIdOfSNFST);
    }

    function lockSNFST(address _primaryUser, uint256 _tokenIdOfSNFST, bool _isKeepOrder) public {
        require(snfstOfAddress[_primaryUser].length > 0, "The balance of SNFST is 0.");

        SNFSTInfo storage info = snfstInfo[_tokenIdOfSNFST];

        require(_primaryUser == info.owner, "Not the owner of this SNFST.");
        require(!info.isLock, "Already lock.");

        info.isLock = true;

        removeUintFromArray(unlockedSNFSTOfAddress[_primaryUser], _tokenIdOfSNFST, false);
        lockedSNFSTOfAddress[_primaryUser].push(_tokenIdOfSNFST);

        if (_isKeepOrder) {
            removeUintFromArray(snfstLockOrder[_primaryUser], _tokenIdOfSNFST, true);
        }

        emit LOCK_SNFST(_primaryUser, _tokenIdOfSNFST);
    }

    function unlockSNFST(address _primaryUser, uint256 _tokenIdOfSNFST, bool _isKeepOrder) public {
        require(snfstOfAddress[_primaryUser].length > 0, "The balance of SNFST is 0.");

        SNFSTInfo storage info = snfstInfo[_tokenIdOfSNFST];

        require(_primaryUser == info.owner, "Not the owner of this SNFST.");
        require(info.isLock, "Already unlock.");

        info.isLock = false;

        removeUintFromArray(lockedSNFSTOfAddress[_primaryUser], _tokenIdOfSNFST, false);
        unlockedSNFSTOfAddress[_primaryUser].push(_tokenIdOfSNFST);

        if (_isKeepOrder) {
            removeUintFromArray(snfstUnlockOrder[_primaryUser], _tokenIdOfSNFST, true);
        }

        emit UNLOCK_SNFST(_primaryUser, _tokenIdOfSNFST);
    }

    function mintSFST(address _to) private OnlyContractOwner {
        require(_to != address(0), "Zero address.");

        uint256 amount = 1 * 10 ** DECIMALS;
        sfstBalance[_to] = sfstBalance[_to] + amount;
        userShares[_to][_to] = userShares[_to][_to] + amount;

        if (!isUserOfPrimaryUser[_to][_to]) {
            userListOfPrimaryUser[_to].push(_to);
            isUserOfPrimaryUser[_to][_to] = true;
        }

        totalSupplyOfSFST = totalSupplyOfSFST + amount;

        emit TRANDFER_SFST(address(0), _to, address(0), amount);
    }

    function transferSFST(address _from, address _to, address _primaryUser, uint256 _amount) private {
        require(_from != address(0) && _to != address(0), "Zero address.");
        require(_amount > 0, "Invalid amount.");
        require(SMA.getIsPrimaryUser(_primaryUser), "The address of primary user is error.");
        require(userShares[_primaryUser][_from] >= _amount, "Balance of SFT is not enough.");

        sfstBalance[_from] = sfstBalance[_from] - _amount;
        sfstBalance[_to] = sfstBalance[_to] + _amount;

        userShares[_primaryUser][_from] = userShares[_primaryUser][_from] - _amount;
        userShares[_primaryUser][_to] = userShares[_primaryUser][_to] + _amount;

        if (_from != _primaryUser && userShares[_primaryUser][_from] == 0) {
            isUserOfPrimaryUser[_primaryUser][_from] = false;
            removeAddressFromArray(userListOfPrimaryUser[_primaryUser], _from, false);
        }

        if (!isUserOfPrimaryUser[_primaryUser][_to]) {
            isUserOfPrimaryUser[_primaryUser][_to] = true;
            userListOfPrimaryUser[_primaryUser].push(_to);
        }

        emit TRANDFER_SFST(_from, _to, _primaryUser, _amount);
    }

    function transfer(address _sender, address _recipient, address _primaryUser, uint256 _amount) public {
        require(_sender != address(0) && _recipient != address(0), "Zero address.");
        require(_sender != _recipient, "Sender and recipient can not be equal.");
        require(_amount > 0, "Invalid amount.");
        require(SMA.getIsPrimaryUser(_primaryUser), "The address of primary user is error.");
        require(userShares[_primaryUser][_sender] >= _amount, "Balance of SFT is not enough.");

        uint256 unit = 10 ** DECIMALS;

        uint256 senderOldShare = userShares[_primaryUser][_sender] / unit;
        uint256 recipientOldShare = userShares[_primaryUser][_recipient] / unit;

        transferSFST(_sender, _recipient, _primaryUser, _amount);

        uint256 senderNewShare = userShares[_primaryUser][_sender] / unit;
        uint256 recipientNewShare = userShares[_primaryUser][_recipient] / unit;

        if (_sender == _primaryUser) {
            uint256 lockNum = senderOldShare - senderNewShare;
            if (lockNum <= snfstLockOrder[_primaryUser].length) {
                for (uint256 i = 0; i < lockNum; i++) {
                    lockSNFST(_primaryUser, snfstLockOrder[_primaryUser][0], true);
                }
            } else {
                for (uint256 i = 0; i < snfstLockOrder[_primaryUser].length; i++) {
                    lockSNFST(_primaryUser, snfstLockOrder[_primaryUser][0], true);
                }

                for (uint256 i = 0; i < lockNum - snfstLockOrder[_primaryUser].length; i++) {
                    lockSNFST(_primaryUser, unlockedSNFSTOfAddress[_primaryUser][0], false);
                }
            }
        }

        if (_recipient == _primaryUser) {
            uint256 unlockNum = recipientNewShare - recipientOldShare;
            if (unlockNum <= snfstUnlockOrder[_primaryUser].length) {
                for (uint256 i = 0; i < unlockNum; i++) {
                    unlockSNFST(_primaryUser, snfstUnlockOrder[_primaryUser][0], true);
                }
            } else {
                for (uint256 i = 0; i < snfstUnlockOrder[_primaryUser].length; i++) {
                    unlockSNFST(_primaryUser, snfstUnlockOrder[_primaryUser][0], true);
                }

                for (uint256 i = 0; i < unlockNum - snfstUnlockOrder[_primaryUser].length; i++) {
                    unlockSNFST(_primaryUser, lockedSNFSTOfAddress[_primaryUser][0], false);
                }
            }
        }

        emit TRANSFER(_sender, _recipient, _amount);
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
        SNFSTInfo storage info = snfstInfo[_tokenIdOfSNFST];

        return (
            info.tokenIdOfSNFST,
            info.tokenIdOfNFST,
            info.owner,
            info.isLock,
            info.isRetrieve,
            info.channel,
            info.location
        );
    }

    function getMintedSNFST() public view returns (uint256[] memory) {
        return mintedSNFST;
    }

    function getRetrieveSNFST() public view returns (uint256[] memory) {
        return retrievedSNFST;
    }

    function getSNFSTOfAddress(address _address) public view returns (uint256[] memory) {
        return snfstOfAddress[_address];
    }

    function getUserListOfPrimaryUser(address _primaryUser) public view returns (address[] memory) {
        return userListOfPrimaryUser[_primaryUser];
    }

    function getSFSTBalance(address _address) public view returns (uint256) {
        return sfstBalance[_address];
    }

    function getUserShares(address _primaryUser, address _user) public view returns (uint256) {
        return userShares[_primaryUser][_user];
    }

    function getOriginOwnerOfNFST(uint256 _tokenIdOfNFST) public view returns (address) {
        return originOwnerOfNFST[_tokenIdOfNFST];
    }

    function setSNFSTLockOrder(uint256[] memory _tokenIdListOfSNFST) public {
        for (uint256 i = 0; i < _tokenIdListOfSNFST.length; i++) {
            SNFSTInfo storage info = snfstInfo[_tokenIdListOfSNFST[i]];

            require(msg.sender == info.owner, "Not the owner.");
            require(!info.isLock, "Already lock.");
        }

        snfstLockOrder[msg.sender] = _tokenIdListOfSNFST;
    }

    function setSNFSTUnlockOrder(uint256[] memory _tokenIdListOfSNFST) public {
        for (uint256 i = 0; i < _tokenIdListOfSNFST.length; i++) {
            SNFSTInfo storage info = snfstInfo[_tokenIdListOfSNFST[i]];

            require(msg.sender == info.owner, "Not the owner.");
            require(info.isLock, "Already unlock.");
        }

        snfstUnlockOrder[msg.sender] = _tokenIdListOfSNFST;
    }

    function getSNFSTLockOrder(address _primaryUser) public view returns (uint256[] memory) {
        return snfstLockOrder[_primaryUser];
    }

    function getSNFSTUnlockOrder(address _primaryUser) public view returns (uint256[] memory) {
        return snfstUnlockOrder[_primaryUser];
    }

    function getLockedSNFST(address _primaryUser) public view returns (uint256[] memory) {
        return lockedSNFSTOfAddress[_primaryUser];
    }

    function getUnlockedSNFST(address _primaryUser) public view returns (uint256[] memory) {
        return unlockedSNFSTOfAddress[_primaryUser];
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

    function removeAddressFromArray(address[] storage _array, address _value, bool _isKeepOrder) private {
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
