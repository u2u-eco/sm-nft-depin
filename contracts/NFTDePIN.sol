// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./NFTDePINVerify.sol";

contract NFTDePIN is ERC721,ERC721Enumerable,Pausable, Ownable {
    event VerifyUpdated(address indexed sender, address indexed addressVerify);
    event WhiteListUpdated(address indexed account, bool indexed status);
    event BlackListUpdated(address indexed account, bool indexed status);

    event ClaimNFT(address indexed to, string indexed uuid, uint256 indexed nonce,uint256[]ids, uint256 amountNft,bytes signature);

    using Counters for Counters.Counter;
    Counters.Counter public idGenerate;
    uint public constant TOTAL_NFT = 40000;
    address public verifyAddress;
    mapping(uint => bool) public claimed;
    string public _baseNftURI;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public isBlackListed;
    uint256 public TGE_TIME ;
    uint256 public LOCK_TIME = 6*4 weeks;

    constructor() ERC721("U2U DePIN Subnet Node", "DePIN") {        
        TGE_TIME = block.timestamp;
    }
    function addWhiteList(address user) external onlyOwner {
        require(!whitelist[user], "DP: account is whitelsited");
        whitelist[user] = true;
        emit WhiteListUpdated(user, true);
    }

    function removeWhiteList(address user) external onlyOwner {
        require(whitelist[user], "DP: account is not whitelisted");
        delete whitelist[user];
        emit WhiteListUpdated(user, false);
    }
    
    function addBlackList(address _evilUser) external onlyOwner {
        require(!isBlackListed[_evilUser],"DP: account is blacklisted");
        isBlackListed[_evilUser] = true;
        emit BlackListUpdated(_evilUser, true);
    }

    function removeBlackList(address _clearedUser) external onlyOwner {
        require(isBlackListed[_clearedUser], "DP: account is not blacklisted");
        delete isBlackListed[_clearedUser];
        emit BlackListUpdated(_clearedUser, false);
    }
    
    function setAddressVerify(address _verifyAddress) external onlyOwner {
        verifyAddress = _verifyAddress;
        emit VerifyUpdated(_msgSender(), verifyAddress);
    }

    function claimNft(
        uint256 nonce,
        uint256 amountNft,
        address to,
        string calldata uuid,        
        bytes calldata signature
    ) external {
        require(verifyAddress!=address(0), "DP: address verify zero");
        uint claimId = uint256(keccak256(abi.encode(keccak256(bytes(uuid)))));
        require(!claimed[claimId],"DP: nft claimed");      
        NFTDePINVerify verifyContract = NFTDePINVerify(payable(verifyAddress));
        require(verifyContract.verify(nonce, amountNft, to, uuid, signature), "DP: signature invalid");
        claimed[claimId] = true;
        uint256[] memory ids = new uint256[](amountNft);
        for(uint256 i = 0; i < amountNft; i++){
            idGenerate.increment();
            uint256 tokenId = idGenerate.current();
            require(tokenId <= TOTAL_NFT, "DP: tokenId invalid");
            _safeMint(to, tokenId);
            ids[i] =tokenId;
        }
        emit ClaimNFT(to, uuid, nonce, ids, amountNft, signature);
    }

    function setBaseURI(string calldata uri) external onlyOwner{
        _baseNftURI = uri;
    }

    function safeMint(address to) public onlyOwner {
         idGenerate.increment();
         uint256 tokenId = idGenerate.current();
        _safeMint(to, tokenId);
    }
    
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId,uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable) whenNotPaused
    {
        require(block.timestamp > TGE_TIME + LOCK_TIME || whitelist[to]||whitelist[from], "DP: transfer not allowed");
        require(!isBlackListed[from] && !isBlackListed[to], "DP: address is blacklisted");
        super._beforeTokenTransfer(from, to, tokenId,batchSize);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseNftURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}