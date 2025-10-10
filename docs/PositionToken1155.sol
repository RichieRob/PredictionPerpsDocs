```solidity
// SPDX-License-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Types.sol";
import "./StorageLib.sol";

contract PositionToken1155 is ERC1155 {
    address public immutable ledger;
    mapping(uint256 => string) public marketNames;
    mapping(uint256 => string) public marketTickers;
    mapping(uint256 => string) public positionNames;
    mapping(uint256 => string) public positionTickers;

    constructor(address _ledger) ERC1155("") {
        ledger = _ledger;
    }

    function mint(address to, uint256 tokenId, uint256 amount) external {
        require(msg.sender == ledger, "Only ledger");
        _mint(to, tokenId, amount, "");
    }

    function burnFrom(address from, uint256 tokenId, uint256 amount) external {
        require(msg.sender == ledger, "Only ledger");
        _burn(from, tokenId, amount);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        require(msg.sender == ledger, "Only ledger");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function setMarketMetadata(uint256 marketId, string calldata name, string calldata ticker) external {
        require(msg.sender == ledger, "Only ledger");
        marketNames[marketId] = name;
        marketTickers[marketId] = ticker;
    }

    function setPositionMetadata(uint256 tokenId, string calldata name, string calldata ticker) external {
        require(msg.sender == ledger, "Only ledger");
        positionNames[tokenId] = name;
        positionTickers[tokenId] = ticker;
    }

    function getMarketName(uint256 marketId) external view returns (string memory) {
        return marketNames[marketId];
    }

    function getMarketTicker(uint256 marketId) external view returns (string memory) {
        return marketTickers[marketId];
    }

    function getPositionName(uint256 tokenId) external view returns (string memory) {
        return positionNames[tokenId];
    }

    function getPositionTicker(uint256 tokenId) external view returns (string memory) {
        return positionTickers[tokenId];
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        Types.TokenData memory data = StorageLib.decodeTokenId(tokenId);
        string memory positionName = positionNames[tokenId];
        string memory marketName = marketNames[data.marketId];
        string memory name = bytes(positionName).length > 0 ? positionName : string.concat(data.isBack ? "Back " : "Lay ", "Position ", Strings.toString(data.positionId));
        string memory description = string.concat(
            data.isBack ? "Back" : "Lay",
            " token for position ",
            Strings.toString(data.positionId),
            " in market ",
            Strings.toString(data.marketId)
        );

        string memory json = string.concat(
            '{"name":"', name, '",',
            '"description":"', description, '",',
            '"attributes":[{"trait_type":"Market ID","value":', Strings.toString(data.marketId), '},',
            '{"trait_type":"Position ID","value":', Strings.toString(data.positionId), '},',
            '{"trait_type":"Type","value":"', data.isBack ? "Back" : "Lay", '"}]}'
        );

        string memory base64 = encodeBase64(json);
        return string.concat("data:application/json;base64,", base64);
    }

    // Helper function to encode string to base64 (simplified, assumes external implementation)
    function encodeBase64(string memory data) private pure returns (string memory) {
        // Simplified: In practice, use a library like Base64.sol for production
        return data; // Placeholder, replace with actual base64 encoding
    }
}
```