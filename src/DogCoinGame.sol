// Audit Report for DogCoinGame.sol

/* General Observations:
 * The contract intends to create a game where players can enter by paying 1 ETH,
 * and winners are rewarded after 200 players have entered. The code presents
 * several issues that should be addressed to ensure it operates securely and as intended.
 */

// Concerns:
/* 1. Value Check: The comparison 'msg.value == 1' should be 'msg.value == 1 ether'
 * to correctly require a 1 ETH payment for function 'addPlayer'.
 * 2. Player Count Logic: The 'addPlayer' function increments 'numberPlayers' without
 * checking if the player was successfully added, potentially leading to incorrect player count.
 * 3. Payout Trigger: The 'startPayout' event can be triggered multiple times if 'addPlayer'
 * is called more than once after reaching 200 players. This should be prevented.
 * 4. Winner Payment Logic: In 'payout', dividing the number of winners by 100 does not
 * make sense. This should be reviewed to implement correct payout logic.
 * 5. Iteration Bounds: In 'payWinners', the loop should use 'i < winners.length' to prevent
 * an out-of-bounds error.
 * 6. Use of send: The 'send' function is used without checking the return value in 'payWinners',
 * which is unsafe. Consider using 'transfer' or 'call' with proper error handling.
 * 7. Potential Reentrancy: No reentrancy protection is in place for 'payWinners'. This could
 * lead to reentrancy attacks.
 * 8. Gas Limit and Loops: The for loop in 'payWinners' might hit the gas limit with a high
 * number of winners, causing it to fail. Consider using a withdrawal pattern instead.
 * 9. No Validation for 'addWinner': Any address can call 'addWinner' and there's no validation
 * to ensure that only eligible players can be added to the winners array.
 */

/* Recommendations:
 * - Implement checks to ensure 'addPlayer' and 'addWinner' are called by authorized parties.
 * - Review the payment logic for distributing rewards to ensure it aligns with the intended design.
 * - Add checks for the successful execution of 'send' and consider limiting the loop to prevent gas issues.
 * - Establish reentrancy guards to secure contract funds against potential attacks.
 * - Freeze the codebase before the audit to avoid reviewing a moving target.
 */


pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DogCoinGame is ERC20 {
    uint256 public currentPrize;
    uint256 public numberPlayers;
    address payable[] public players;
    address payable[] public winners;

    event startPayout();

    constructor() ERC20("DogCoin", "DOG") {}

    function addPlayer(address payable _player) public payable {
        if (msg.value == 1) {
            players.push(_player);
        }
        numberPlayers++;
        if (numberPlayers > 200) {
            emit startPayout();
        }
    }

    function addWinner(address payable _winner) public {
        winners.push(_winner);
    }

    function payout() public {
        if (address(this).balance == 100) {
            uint256 amountToPay = winners.length / 100;
            payWinners(amountToPay);
        }
    }

    function payWinners(uint256 _amount) public {
        for (uint256 i = 0; i <= winners.length; i++) {
            winners[i].send(_amount);
        }
    }
}
