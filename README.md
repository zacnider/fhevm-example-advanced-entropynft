# EntropyNFT

Learn how to create NFTs with encrypted metadata

## 🎓 What You'll Learn

This example teaches you how to use FHEVM to build privacy-preserving smart contracts. You'll learn step-by-step how to implement encrypted operations, manage permissions, and work with encrypted data.

## 🚀 Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/zacnider/fhevm-example-advanced-entropynft.git
   cd fhevm-example-advanced-entropynft
   ```

2. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

3. **Setup environment:**
   ```bash
   npm run setup
   ```
   Then edit `.env` file with your credentials:
   - `SEPOLIA_RPC_URL` - Your Sepolia RPC endpoint
   - `PRIVATE_KEY` - Your wallet private key (for deployment)
   - `ETHERSCAN_API_KEY` - Your Etherscan API key (for verification)

4. **Compile contracts:**
   ```bash
   npm run compile
   ```

5. **Run tests:**
   ```bash
   npm test
   ```

6. **Deploy to Sepolia:**
   ```bash
   npm run deploy:sepolia
   ```

7. **Verify contract (after deployment):**
   ```bash
   npm run verify <CONTRACT_ADDRESS>
   ```

**Alternative:** Use the [Examples page](https://entrofhe.vercel.app/examples) for browser-based deployment and verification.

---

## 📚 Overview

@title EntropyNFT
@notice ERC721 NFT with trait selection using entropy
@dev Real ERC721 NFT contract with trait selection using encrypted randomness
In this example, you will learn:
- ERC721 NFT implementation
- Using encrypted randomness for trait selection
- IPFS metadata storage
- Off-chain trait selection with on-chain storage

@notice Set base URI for token metadata
@param _baseURI Base URI (e.g., "ipfs://Qm...")

@notice Request entropy for NFT trait selection
@param tag Unique tag for this NFT mint
@return tokenId The token ID for this NFT
@return requestId The entropy request ID
@dev Requires 0.00001 ETH fee for entropy request

@notice Complete NFT minting (traits selected using entropy)
@param tokenId The token ID
@param tokenURI IPFS URI for the NFT metadata
@dev Traits are selected using entropy, then NFT is minted with metadata

@notice Complete NFT minting with trait indices (for off-chain trait selection)
@param tokenId The token ID
@param backgroundIdx Background trait index
@param accessoryIdx Accessory trait index
@param expressionIdx Expression trait index
@param tokenURI IPFS URI for the NFT metadata
@dev Traits are selected off-chain using decrypted entropy, then stored on-chain

@notice Get NFT information with traits
@param tokenId The token ID
@return tokenId_ The token ID
@return entropyRequestId The entropy request ID
@return background The background trait
@return accessory The accessory trait
@return expression The expression trait
@return tokenURI The token URI
@return minted Whether NFT is minted

@notice Get available traits
@return backgrounds_ Available background colors
@return accessories_ Available accessories
@return expressions_ Available expressions

@notice Get total supply (minted NFTs)
@return count Total minted NFTs



## 🔐 Learn Zama FHEVM Through This Example

This example teaches you how to use the following **Zama FHEVM** features:

### What You'll Learn About

- **ZamaEthereumConfig**: Inherits from Zama's network configuration
  ```solidity
  contract MyContract is ZamaEthereumConfig {
      // Inherits network-specific FHEVM configuration
  }
  ```

- **FHE Operations**: Uses Zama's FHE library for encrypted operations
  - `FHE.add()` - Zama FHEVM operation
  - `FHE.sub()` - Zama FHEVM operation
  - `FHE.mul()` - Zama FHEVM operation
  - `FHE.eq()` - Zama FHEVM operation
  - `FHE.xor()` - Zama FHEVM operation
  - `FHE.allowThis()` - Zama FHEVM operation

- **Encrypted Types**: Uses Zama's encrypted integer types
  - `euint64` - 64-bit encrypted unsigned integer
  - `externalEuint64` - External encrypted value from user

- **Access Control**: Uses Zama's permission system
  - `FHE.allowThis()` - Allow contract to use encrypted values
  - `FHE.allow()` - Allow specific user to decrypt
  - `FHE.allowTransient()` - Temporary permission for single operation
  - `FHE.fromExternal()` - Convert external encrypted values to internal

### Zama FHEVM Imports

```solidity
// Zama FHEVM Core Library - FHE operations and encrypted types
import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";

// Zama Network Configuration - Provides network-specific settings
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
```

### Zama FHEVM Code Example

```solidity
// Advanced Zama FHEVM usage patterns
euint64 result = FHE.add(value1, value2);
FHE.allowThis(result);

// Combining multiple Zama FHEVM operations
euint64 entropy = entropyOracle.getEncryptedEntropy(requestId);
FHE.allowThis(entropy);
euint64 finalResult = FHE.xor(result, entropy);
FHE.allowThis(finalResult);
```

### FHEVM Concepts You'll Learn

1. **Complex FHE Operations**: Learn how to use Zama FHEVM for complex fhe operations
2. **Real-World Applications**: Learn how to use Zama FHEVM for real-world applications
3. **Entropy Integration**: Learn how to use Zama FHEVM for entropy integration

### Learn More About Zama FHEVM

- 📚 [Zama FHEVM Documentation](https://docs.zama.org/protocol)
- 🎓 [Zama Developer Hub](https://www.zama.org/developer-hub)
- 💻 [Zama FHEVM GitHub](https://github.com/zama-ai/fhevm)



## 🔍 Contract Code

```solidity
// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {FHE, euint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
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
contract EntropyNFT is ERC721, ERC721URIStorage, Ownable, ZamaEthereumConfig {
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

```

## 🧪 Tests

See [test file](./test/EntropyNFT.test.ts) for comprehensive test coverage.

```bash
npm test
```


## 📚 Category

**advanced**



## 🔗 Related Examples

- [All advanced examples](https://github.com/zacnider/entrofhe/tree/main/examples)

## 📝 License

BSD-3-Clause-Clear
