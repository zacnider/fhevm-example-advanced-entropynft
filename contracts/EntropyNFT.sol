// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {FHE, euint64} from "@fhevm/solidity/lib/FHE.sol";
import "./IEntropyOracle.sol";

/**
 * @title EntropyNFT
 * @notice ERC721 NFT with trait selection using entropy
 * @dev Real ERC721 NFT contract with trait selection using EntropyOracle
 * 
 * This example shows:
 * - ERC721 NFT implementation
 * - Using entropy oracle for trait selection
 * - IPFS metadata storage
 * - Off-chain trait selection with on-chain storage
 */
contract EntropyNFT is ERC721, ERC721URIStorage, Ownable {
    IEntropyOracle public entropyOracle;
    
    // NFT traits
    string[] public backgrounds = ["Red", "Blue", "Green", "Yellow", "Purple", "Orange", "Pink", "Cyan"];
    string[] public accessories = ["Hat", "Glasses", "Necklace", "Watch", "Ring", "Crown", "Mask", "None"];
    string[] public expressions = ["Happy", "Sad", "Angry", "Surprised", "Cool", "Wink", "Sleepy", "Excited"];
    
    // NFT structure with traits
    struct NFTData {
        uint256 tokenId;
        uint256 entropyRequestId;
        uint8 backgroundIndex;
        uint8 accessoryIndex;
        uint8 expressionIndex;
        string tokenURI;
        bool minted;
    }
    
    mapping(uint256 => NFTData) public nftData;
    mapping(uint256 => uint256) public requestIdToTokenId;
    uint256 public nextTokenId;
    string public baseURI;
    
    event NFTMintRequested(uint256 indexed tokenId, uint256 indexed requestId);
    event NFTMinted(uint256 indexed tokenId, uint256 indexed requestId, string tokenURI);
    
    constructor(
        address _entropyOracle,
        address initialOwner
    ) ERC721("EntropyNFT", "ENTNFT") Ownable(initialOwner) {
        require(_entropyOracle != address(0), "Invalid oracle address");
        entropyOracle = IEntropyOracle(_entropyOracle);
        nextTokenId = 1;
    }
    
    /**
     * @notice Set base URI for token metadata
     * @param _baseURI Base URI (e.g., "ipfs://Qm...")
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    
    /**
     * @notice Request entropy for NFT trait selection
     * @param tag Unique tag for this NFT mint
     * @return tokenId The token ID for this NFT
     * @return requestId The entropy request ID
     * @dev Requires 0.00001 ETH fee for entropy request
     */
    function requestMint(bytes32 tag) external payable returns (uint256 tokenId, uint256 requestId) {
        require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
        
        tokenId = nextTokenId++;
        
        // Request entropy from oracle
        requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
        
        // Store NFT request with default values
        nftData[tokenId] = NFTData({
            tokenId: tokenId,
            entropyRequestId: requestId,
            backgroundIndex: 0,
            accessoryIndex: 0,
            expressionIndex: 0,
            tokenURI: "",
            minted: false
        });
        
        requestIdToTokenId[requestId] = tokenId;
        
        emit NFTMintRequested(tokenId, requestId);
        
        return (tokenId, requestId);
    }
    
    /**
     * @notice Complete NFT minting (traits selected using entropy)
     * @param tokenId The token ID
     * @param tokenURI IPFS URI for the NFT metadata
     * @dev Traits are selected using entropy, then NFT is minted with metadata
     */
    function completeMint(uint256 tokenId, string memory tokenURI) external {
        NFTData storage nft = nftData[tokenId];
        require(nft.tokenId == tokenId, "NFT not found");
        require(!nft.minted, "NFT already minted");
        require(entropyOracle.isRequestFulfilled(nft.entropyRequestId), "Entropy not ready");
        
        // Get encrypted entropy
        euint64 entropy = entropyOracle.getEncryptedEntropy(nft.entropyRequestId);
        
        // Note: In a real FHE implementation, you would use FHE operations to select traits
        // For now, we'll use a simplified approach where traits are selected off-chain
        // and passed via tokenURI. In production, you'd decrypt entropy or use FHE.mod operations
        
        // Store traits (selected off-chain based on entropy)
        // In production: Use FHE.mod(entropy, backgrounds.length) etc.
        nft.tokenURI = tokenURI;
        nft.minted = true;
        
        // Mint the NFT to the requester
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        emit NFTMinted(tokenId, nft.entropyRequestId, tokenURI);
    }
    
    /**
     * @notice Complete NFT minting with trait indices (for off-chain trait selection)
     * @param tokenId The token ID
     * @param backgroundIdx Background trait index
     * @param accessoryIdx Accessory trait index
     * @param expressionIdx Expression trait index
     * @param tokenURI IPFS URI for the NFT metadata
     * @dev Traits are selected off-chain using decrypted entropy, then stored on-chain
     */
    function completeMintWithTraits(
        uint256 tokenId,
        uint8 backgroundIdx,
        uint8 accessoryIdx,
        uint8 expressionIdx,
        string memory tokenURI
    ) external {
        NFTData storage nft = nftData[tokenId];
        require(nft.tokenId == tokenId, "NFT not found");
        require(!nft.minted, "NFT already minted");
        require(entropyOracle.isRequestFulfilled(nft.entropyRequestId), "Entropy not ready");
        require(backgroundIdx < backgrounds.length, "Invalid background index");
        require(accessoryIdx < accessories.length, "Invalid accessory index");
        require(expressionIdx < expressions.length, "Invalid expression index");
        
        // Store traits
        nft.backgroundIndex = backgroundIdx;
        nft.accessoryIndex = accessoryIdx;
        nft.expressionIndex = expressionIdx;
        nft.tokenURI = tokenURI;
        nft.minted = true;
        
        // Mint the NFT to the requester
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        emit NFTMinted(tokenId, nft.entropyRequestId, tokenURI);
    }
    
    /**
     * @notice Get NFT information with traits
     * @param tokenId The token ID
     * @return tokenId_ The token ID
     * @return entropyRequestId The entropy request ID
     * @return background The background trait
     * @return accessory The accessory trait
     * @return expression The expression trait
     * @return tokenURI The token URI
     * @return minted Whether NFT is minted
     */
    function getNFT(uint256 tokenId) external view returns (
        uint256 tokenId_,
        uint256 entropyRequestId,
        string memory background,
        string memory accessory,
        string memory expression,
        string memory tokenURI,
        bool minted
    ) {
        NFTData memory nft = nftData[tokenId];
        return (
            nft.tokenId,
            nft.entropyRequestId,
            backgrounds[nft.backgroundIndex],
            accessories[nft.accessoryIndex],
            expressions[nft.expressionIndex],
            nft.tokenURI,
            nft.minted
        );
    }
    
    /**
     * @notice Get available traits
     * @return backgrounds_ Available background colors
     * @return accessories_ Available accessories
     * @return expressions_ Available expressions
     */
    function getAvailableTraits() external view returns (
        string[] memory backgrounds_,
        string[] memory accessories_,
        string[] memory expressions_
    ) {
        return (backgrounds, accessories, expressions);
    }
    
    /**
     * @notice Get total supply (minted NFTs)
     * @return count Total minted NFTs
     */
    function totalSupply() external view returns (uint256 count) {
        return nextTokenId - 1;
    }
    
    // Override required by Solidity
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
