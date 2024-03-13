// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DogCoinGame is ERC20, ReentrancyGuard {
    uint256 public numberPlayers;
    address payable[] public players;
    address payable[] public winners;
    bool public gameStarted;
    bool public payoutInitiated;

    event StartPayout();
    event PlayerAdded(address player);
    event WinnerAdded(address winner);
    event WinnersPaid();

    constructor() ERC20("DogCoin", "DOG") {}

    modifier gameNotStarted() {
        require(!gameStarted, "Game has already started.");
        _;
    }

    modifier onlyWinner() {
        bool isWinner = false;
        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i] == msg.sender) {
                isWinner = true;
                break;
            }
        }
        require(isWinner, "Caller is not a winner.");
        _;
    }

    function addPlayer(address payable _player) public payable gameNotStarted {
        require(msg.value == 1 ether, "Must send exactly 1 ETH to play.");
        players.push(_player);
        numberPlayers++;

        emit PlayerAdded(_player);

        if (numberPlayers == 200) {
            gameStarted = true;
            emit StartPayout();
        }
    }

    // This should be restricted to only the game organizer or via secure logic
    function addWinner(address payable _winner) public gameNotStarted {
        winners.push(_winner);
        emit WinnerAdded(_winner);
    }

    function payout() public nonReentrant {
        require(gameStarted, "Game has not started yet.");
        require(!payoutInitiated, "Payout has already been initiated.");
        require(
            address(this).balance >= winners.length * 1 ether,
            "Insufficient balance for payout."
        );

        payoutInitiated = true;

        uint256 amountToPay = 1 ether;
        for (uint256 i = 0; i < winners.length; i++) {
            (bool sent, ) = winners[i].call{value: amountToPay}("");
            require(sent, "Failed to send Ether to winner.");
        }

        emit WinnersPaid();
    }

    // Allow winners to withdraw their rewards
    function withdrawReward() public onlyWinner nonReentrant {
        require(payoutInitiated, "Payout not initiated.");
        uint256 rewardAmount = address(this).balance / winners.length;
        require(rewardAmount > 0, "No reward available.");

        (bool sent, ) = msg.sender.call{value: rewardAmount}("");
        require(sent, "Failed to withdraw reward.");
    }

    // Fallback function to receive Ether
    receive() external payable {
        revert("Please use the addPlayer function to send Ether.");
    }
}
