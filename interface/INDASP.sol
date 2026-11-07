// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INDASP {
    function getUserListOfPrimaryUser(address _primaryUser) external view returns (address[] memory);
    
    function getUserShares(address _primaryUser, address _user) external view returns (uint256);
    
    function getSNFSTInfo(uint256 _tokenId) external view returns (
        uint256 tokenIdOfSNFST,
        uint256 tokenIdOfNFST,
        address owner,
        bool isLock,
        bool isRetrieve,
        string memory channel,
        string memory location
    );

    function transfer(address _sender, address _recipient, address _primaryUser, uint256 _amount) external;
    
}
