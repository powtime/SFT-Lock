// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISMA {
    function getIsPrimaryUser(address _address) external view returns (bool);

    function transferNFST(address _from, address _to, uint256 _tokenId) external;

    function getNFSTInfo(uint256 _tokenId) external view returns (
        uint256 tokenId,
        address owner,
        bool isStack,
        bool isReclaim,
        string memory channel,
        string memory location
    );

    function getIsUpload(string calldata _channel, string calldata _location) external view returns (bool);

    function setStakeInfoOfNFST(uint256 _tokenId, address _owner, bool _isStack) external;

}
