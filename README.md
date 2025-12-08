# EntropyNFT

ERC721 NFT with trait selection using entropy oracle

## 🚀 Standard workflow
- Install (first run): `npm install --legacy-peer-deps`
- Compile: `npx hardhat compile`
- Test (local FHE + local oracle/chaos engine auto-deployed): `npx hardhat test`
- Deploy (frontend Deploy button): constructor args fixed to EntropyOracle and initialOwner; oracle is `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
- Verify: `npx hardhat verify --network sepolia <contractAddress> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361 <initialOwner>`

## 📋 Overview

This example demonstrates **advanced** concepts in FHEVM with **EntropyOracle integration**:
- ERC721 NFT implementation
- Trait selection using encrypted entropy
- IPFS metadata storage
- Two-phase minting (request + complete)
- Real-world NFT minting pattern

## 🎯 What This Example Teaches

This tutorial will teach you:

1. **How to implement ERC721 NFTs** with FHE and entropy
2. **How to select NFT traits** using encrypted entropy
3. **Two-phase minting pattern** (request + complete)
4. **IPFS metadata integration** for NFT metadata
5. **Trait management** with encrypted randomness
6. **Real-world NFT minting** with fair trait selection

## 💡 Why This Matters

NFTs need random trait selection to be fair:
- **Prevents manipulation** of NFT traits
- **Fair and unpredictable** trait selection
- **Verifiable randomness** from EntropyOracle
- **Privacy-preserving** trait selection (encrypted)
- **Real-world application** of FHE and entropy in NFTs

## 🔍 How It Works

### Contract Structure

The contract has five main components:

1. **Request Mint**: Request entropy for trait selection
2. **Complete Mint**: Complete minting after entropy is ready
3. **Complete Mint with Traits**: Complete minting with off-chain selected traits
4. **Get NFT**: Retrieve NFT information with traits
5. **Get Available Traits**: View available trait options

### Step-by-Step Code Explanation

#### 1. Constructor

```solidity
constructor(
    address _entropyOracle,
    address initialOwner
) ERC721("EntropyNFT", "ENTNFT") Ownable(initialOwner) {
    require(_entropyOracle != address(0), "Invalid oracle address");
    entropyOracle = IEntropyOracle(_entropyOracle);
    nextTokenId = 1;
}
```

**What it does:**
- Takes EntropyOracle address and initial owner
- Validates oracle address is not zero
- Initializes ERC721 token with name and symbol
- Sets up ownership
- Initializes token ID counter

**Why it matters:**
- Must use the correct oracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
- Owner can set base URI for metadata

#### 2. Request Mint

```solidity
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
    
    return (tokenId, requestId);
}
```

**What it does:**
- Validates fee payment
- Generates new token ID
- Requests entropy from EntropyOracle
- Stores NFT request data (not minted yet)
- Links request ID to token ID
- Returns token ID and request ID

**Key concepts:**
- **Two-phase minting**: Request first, complete later
- **Entropy request**: Gets randomness for trait selection
- **Pending state**: NFT not minted until entropy is ready

**Why two-phase:**
- Entropy generation takes time
- Allows trait selection after entropy is ready
- Better user experience

#### 3. Complete Mint

```solidity
function completeMint(uint256 tokenId, string memory tokenURI) external {
    NFTData storage nft = nftData[tokenId];
    require(!nft.minted, "NFT already minted");
    require(entropyOracle.isRequestFulfilled(nft.entropyRequestId), "Entropy not ready");
    
    // Get encrypted entropy
    euint64 entropy = entropyOracle.getEncryptedEntropy(nft.entropyRequestId);
    
    // Traits selected off-chain based on entropy
    // In production: Use FHE.mod(entropy, backgrounds.length) etc.
    nft.tokenURI = tokenURI;
    nft.minted = true;
    
    // Mint the NFT
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, tokenURI);
    
    emit NFTMinted(tokenId, nft.entropyRequestId, tokenURI);
}
```

**What it does:**
- Checks NFT is not already minted
- Checks entropy is ready
- Gets encrypted entropy from oracle
- Stores token URI (traits selected off-chain)
- Mints NFT to requester
- Sets token URI
- Emits mint event

**Key concepts:**
- **Off-chain trait selection**: Traits selected using decrypted entropy
- **IPFS metadata**: Token URI points to IPFS metadata
- **NFT minting**: Standard ERC721 minting

**Why off-chain selection:**
- FHE operations for trait selection are complex
- Off-chain selection is simpler for this example
- Production: Use FHE.mod operations for on-chain selection

#### 4. Complete Mint with Traits

```solidity
function completeMintWithTraits(
    uint256 tokenId,
    uint8 backgroundIdx,
    uint8 accessoryIdx,
    uint8 expressionIdx,
    string memory tokenURI
) external {
    NFTData storage nft = nftData[tokenId];
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
    
    // Mint the NFT
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, tokenURI);
}
```

**What it does:**
- Validates trait indices
- Stores trait indices on-chain
- Stores token URI
- Mints NFT
- Sets token URI

**Key concepts:**
- **Trait indices**: Stored on-chain for easy retrieval
- **Trait validation**: Ensures indices are valid
- **On-chain traits**: Traits stored in contract state

**Why store indices:**
- Easy to retrieve trait names
- Efficient storage
- Can be used in view functions

## 🧪 Step-by-Step Testing

### Prerequisites

1. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

2. **Compile contracts:**
   ```bash
   npx hardhat compile
   ```

### Running Tests

```bash
npx hardhat test
```

### What Happens in Tests

1. **Fixture Setup** (`deployContractFixture`):
   - Deploys FHEChaosEngine, EntropyOracle, and EntropyNFT
   - Returns all contract instances

2. **Test: Request Mint**
   ```typescript
   it("Should request mint", async function () {
     const tag = hre.ethers.id("nft-mint-1");
     const fee = await oracle.getFee();
     const [tokenId, requestId] = await contract.requestMint(tag, { value: fee });
     
     expect(tokenId).to.equal(1);
     expect(requestId).to.not.be.undefined;
   });
   ```
   - Requests mint with unique tag
   - Pays required fee
   - Verifies token ID and request ID returned

3. **Test: Complete Mint**
   ```typescript
   it("Should complete mint", async function () {
     // ... request mint code ...
     await waitForEntropy(requestId);
     
     const tokenURI = "ipfs://Qm...";
     await contract.completeMint(tokenId, tokenURI);
     
     expect(await contract.ownerOf(tokenId)).to.equal(owner.address);
   });
   ```
   - Waits for entropy to be ready
   - Completes mint with IPFS URI
   - Verifies NFT is minted to requester

### Expected Test Output

```
  EntropyNFT
    Deployment
      ✓ Should deploy successfully
      ✓ Should have EntropyOracle address set
    NFT Minting
      ✓ Should request mint
      ✓ Should complete mint after entropy ready
      ✓ Should complete mint with traits
      ✓ Should get NFT information

  6 passing
```

**Note:** Traits are selected using entropy. In production, use FHE operations for on-chain trait selection.

## 🚀 Step-by-Step Deployment

### Option 1: Frontend (Recommended)

1. Navigate to [Examples page](https://entrofhe.vercel.app/examples)
2. Find "EntropyNFT" in Tutorial Examples
3. Click **"Deploy"** button
4. Approve transaction in wallet
5. Wait for deployment confirmation
6. Copy deployed contract address

### Option 2: CLI

1. **Create deploy script** (`scripts/deploy.ts`):
   ```typescript
   import hre from "hardhat";

   async function main() {
     const ENTROPY_ORACLE_ADDRESS = "0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361";
     const [owner] = await hre.ethers.getSigners();
     
     const ContractFactory = await hre.ethers.getContractFactory("EntropyNFT");
     const contract = await ContractFactory.deploy(ENTROPY_ORACLE_ADDRESS, owner.address);
     await contract.waitForDeployment();
     
     const address = await contract.getAddress();
     console.log("EntropyNFT deployed to:", address);
   }

   main().catch((error) => {
     console.error(error);
     process.exitCode = 1;
   });
   ```

2. **Deploy:**
   ```bash
   npx hardhat run scripts/deploy.ts --network sepolia
   ```

## ✅ Step-by-Step Verification

### Option 1: Frontend

1. After deployment, click **"Verify"** button on Examples page
2. Wait for verification confirmation
3. View verified contract on Etherscan

### Option 2: CLI

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361 <INITIAL_OWNER>
```

**Important:** Constructor arguments must be:
1. EntropyOracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
2. Initial owner address: Your deployer address

## 📊 Expected Outputs

### After Request Mint

- `nextTokenId` increments
- NFT request stored (not minted yet)
- `requestIdToTokenId` mapping updated
- `NFTMintRequested` event emitted

### After Complete Mint

- `nftData[tokenId].minted` returns `true`
- NFT minted to requester
- Token URI set
- `NFTMinted` event emitted

### After Get NFT

- `getNFT(tokenId)` returns NFT information
- Includes trait names, token URI, mint status
- Traits retrieved from stored indices

## ⚠️ Common Errors & Solutions

### Error: `Entropy not ready`

**Cause:** Trying to complete mint before entropy is fulfilled.

**Solution:** Always check `isRequestFulfilled()` before completing mint:
```typescript
await waitForEntropy(requestId);
await contract.completeMint(tokenId, tokenURI);
```

---

### Error: `NFT already minted`

**Cause:** Trying to complete mint for already minted NFT.

**Solution:** Check `nft.minted` before completing mint. Each token can only be minted once.

---

### Error: `Invalid background index`

**Cause:** Trait index out of bounds.

**Solution:** Ensure trait indices are within valid range:
```solidity
require(backgroundIdx < backgrounds.length, "Invalid background index");
```

---

### Error: `Insufficient fee`

**Cause:** Not sending enough ETH when requesting mint.

**Solution:** Always send exactly 0.00001 ETH:
```typescript
const fee = await contract.entropyOracle.getFee();
await contract.requestMint(tag, { value: fee });
```

---

### Error: Verification failed - Constructor arguments mismatch

**Cause:** Wrong constructor arguments used during verification.

**Solution:** Always use both EntropyOracle address and initial owner:
```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361 <INITIAL_OWNER>
```

## 🔗 Related Examples

- [SimpleLottery](../advanced-simplelottery/) - Lottery using entropy
- [RandomNumberGenerator](../advanced-randomnumbergenerator/) - Random number generation
- [Category: advanced](../)

## 📚 Additional Resources

- [Full Tutorial Track Documentation](../../../frontend/src/pages/Docs.tsx) - Complete educational guide
- [Zama FHEVM Documentation](https://docs.zama.org/) - Official FHEVM docs
- [GitHub Repository](https://github.com/zacnider/entrofhe/tree/main/examples/advanced-entropynft) - Source code

## 📝 License

BSD-3-Clause-Clear
