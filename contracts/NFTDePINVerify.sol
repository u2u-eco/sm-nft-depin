// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTDePINVerify is Ownable {
    event SignerUpdated(address indexed account, bool indexed status);

    mapping(address => bool) public signers;

    function addSigner(address _signer) external onlyOwner {
        require(_signer != address(0),"DP: invalid address");
        require(!signers[_signer], "DP: account is signer");
        signers[_signer] = true;
        emit SignerUpdated(_signer, true);
    }

    function removeSigner(address _signer) external onlyOwner {
        require(_signer != address(0),"DP: invalid address");
        require(signers[_signer], "DP: account is not signer");
        signers[_signer] = false;
        emit SignerUpdated(_signer, signers[_signer]);
    }

    function getSigner(bytes32 msgHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(msgHash, v, r, s);
    }

    function splitSignature(bytes memory signature)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "DP: invalid signature length");
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }
    function verify(
        uint256 nonce,
        uint256 amountNft,
        address to,
        string calldata uuid,        
        bytes calldata signature
    ) external view returns (bool) {      
        bytes32 _msgHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked("DP_NFT_GENERATE", block.chainid, nonce, amountNft, to, uuid))
            )
        );
        address signer = getSigner(_msgHash, signature);
        return signers[signer];
    }
}