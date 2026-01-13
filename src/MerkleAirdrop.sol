// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20, SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;
    // some list of addresses
    // Allow someone in the list to claim ERC-20 tokens
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    event Claim(address account, uint256 amount);

    address[] claimers;
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_AIRDROP_TOKEN;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        I_MERKLE_ROOT = merkleRoot;
        I_AIRDROP_TOKEN = airdropToken;
    }

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // calculate using the account and the amount, the hash --> leaf node
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount)))); // we hash it twice to save it from the second pre-image attack

        if (!MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_hasClaimed[account] = true;
        emit Claim(account, amount);
        I_AIRDROP_TOKEN.safeTransfer(account, amount);
    }
}
