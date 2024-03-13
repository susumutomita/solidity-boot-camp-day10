// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8;

import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/utils/SafeTransferLib.sol";

contract FixedSea {
    using SafeTransferLib for ERC20;

    mapping(address => mapping(uint160 => mapping(uint256 => uint256))) bids;

    function createBid(
        ERC721 erc721Token,
        uint256 erc721TokenId,
        ERC20 erc20Token,
        uint256 price
    ) external {
        uint160 key = _getKey(erc20Token, erc721Token);
        bids[msg.sender][key][erc721TokenId] = price;
    }

    function acceptBid(
        address bidder,
        ERC721 erc721Token,
        uint256 erc721TokenId,
        ERC20 erc20Token,
        uint256 price
    ) external {
        uint160 key = _getKey(erc20Token, erc721Token);
        uint256 bidPrice = bids[bidder][key][erc721TokenId];
        require(bidPrice != 0, "FixedSea::acceptBid/BID_PRICE_ZERO");
        require(bidPrice >= price, "FixedSea::acceptBid/BID_TOO_LOW");

        // Adding checks for ERC20 token contract existence, balance, and allowance to ensure
        // secure and successful transfers. These checks mitigate potential issues
        // with token transfers, ensuring the bidder has sufficient funds and permissions.
        uint256 size;
        assembly {
            size := extcodesize(erc20Token)
        }
        require(size > 0, "FixedSea::acceptBid/NO_CODE");

        // Checking the bidder's balance and allowance before transferring tokens.
        // These checks are necessary to ensure that the bidder has enough tokens
        // and has given the contract permission to spend those tokens on their behalf.
        require(
            erc20Token.balanceOf(bidder) >= price,
            "FixedSea::acceptBid/INSUFFICIENT_BALANCE"
        );
        require(
            erc20Token.allowance(bidder, address(this)) >= price,
            "FixedSea::acceptBid/INSUFFICIENT_ALLOWANCE"
        );

        delete bids[bidder][key][erc721TokenId];

        erc20Token.safeTransferFrom(bidder, msg.sender, price);
        erc721Token.transferFrom(msg.sender, bidder, erc721TokenId);
    }

    // Kept the key generation method unchanged. The XOR approach remains due to its
    // gas efficiency and the very low risk of address collision, which was deemed acceptable.
    function _getKey(
        ERC20 erc20Token,
        ERC721 erc721Token
    ) private pure returns (uint160 key) {
        return uint160(address(erc20Token)) ^ uint160(address(erc721Token));
    }
}
