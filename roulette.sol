//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Roulette {
    address payable[] public players;
    uint256 public entryfee;
    uint256 bankBalance;
    address creator;
    uint8[] payouts;
    uint256 totalBetAmt;
    mapping(address => uint256) winnings;

    struct Bet {
        address player;
        // max values are 4 considering intersection of 4 nos.
        uint256 value1;
        uint256 value2;
        uint256 value3;
        uint256 value4;
        uint256 betType;
        uint256 amt;
    }
    Bet[] public bets;

    AggregatorV3Interface internal priceFeed;
    enum GameState {
        OPEN, //0
        CLOSED, //1
        CALCULATING //2
    }
    GameState public gameState;

    constructor(address _priceAddress) payable {
        creator = msg.sender;
        entryfee = 10 * (10**18);
        priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        //ethUsdfee = AggregatorV3Interface(<myaddress>);
        gameState = GameState.CLOSED;
        payouts = [1, 17, 8, 11, 2, 2, 1, 1, 35];
        totalBetAmt = 0;
    }

    function bet(
        uint256 betType,
        uint256 value1,
        uint256 value2,
        uint256 value3,
        uint256 value4
    ) public payable {
        /*
        0: Color: Red(0) or black(1)
        1: Line between 2 nos. ?
        2: Intersection of 4 nos.? 0-21
        3: Row: 0-11
        4: Columns: 0-2
        5: Dozens: 0-2 (1-12,13-24,25-36)
        6: Type: Odd(1) or even(0)
        7: Half: 1-18(0) or 19-36(1)
        8: Number: 1-36
        */
        //console.log("hi",entranceFee());
        console.log('hi2',msg.value);
        require(msg.value* 10**18 >= entranceFee());
        require(betType >= 0 && betType <= 8);
        uint256 betAmt = msg.value * payouts[betType];
        uint256 newAmt = totalBetAmt + betAmt;
        //**************************************
        require(newAmt < address(this).balance);
        totalBetAmt += betAmt;
        bets.push(
            Bet({
                betType: betType,
                player: msg.sender,
                value1: value1,
                value2: value2,
                value3: value3,
                value4: value4,
                amt: betAmt
            })
        );
    }

    function playGame() public {
        require(bets.length > 0);
        require(gameState == GameState.OPEN);
        //uint256 number = 17;
        uint diff = block.difficulty;
        bytes32 hash = blockhash(block.number-1);
        Bet memory lb = bets[bets.length-1];
        uint number = uint(keccak256(abi.encodePacked(block.timestamp, diff, hash, lb.betType, lb.player, lb.value1))) % 37;
        console.log(number);
        uint256 totalAmt = totalBetAmt;

        for (uint256 i = 0; i < bets.length; i++) {
            bool won = false;
            Bet memory b = bets[i];
            if (number == 0) {
                won = (b.betType == 8 && b.value1 == 0);
            } else if (b.betType == 8) {
                //number
                won = (b.value1 == number);
            } else if (b.betType == 7) {
                //half
                if (number <= 18) {
                    won = (b.value1 == 0);
                } else if (number > 18 && number <= 36) {
                    won = (b.value1 == 1);
                }
            } else if (b.betType == 6) {
                //odd or even
                if (number % 2 == 0) {
                    won = (b.value1 == 0);
                } else if (number % 2 != 0) {
                    won = (b.value1 == 1);
                }
            } else if (b.betType == 5) //dozens
            {
                if (number >= 1 && number <= 12) {
                    won = (b.value1 == 0);
                } else if (number >= 13 && number <= 24) {
                    won = (b.value1 == 1);
                } else if (number >= 25 && number <= 36) {
                    won = (b.value1 == 2);
                }
            } else if (b.betType == 4) //columns
            {
                if (number % 3 == 1) {
                    won = (b.value1 == 0);
                } else if (number % 3 == 2) {
                    won = (b.value1 == 1);
                } else if (number % 3 == 0) {
                    won = (b.value1 == 2);
                }
            } else if (b.betType == 3) //rows
            {
                if (number >= 1 && number <= 3) {
                    won = (b.value1 == 0);
                } else if (number >= 4 && number <= 6) {
                    won = (b.value1 == 1);
                } else if (number >= 7 && number <= 9) {
                    won = (b.value1 == 2);
                } else if (number >= 10 && number <= 12) {
                    won = (b.value1 == 3);
                } else if (number >= 13 && number <= 15) {
                    won = (b.value1 == 4);
                } else if (number >= 16 && number <= 18) {
                    won = (b.value1 == 5);
                } else if (number >= 19 && number <= 21) {
                    won = (b.value1 == 6);
                } else if (number >= 22 && number <= 24) {
                    won = (b.value1 == 7);
                } else if (number >= 25 && number <= 27) {
                    won = (b.value1 == 8);
                } else if (number >= 28 && number <= 30) {
                    won = (b.value1 == 9);
                } else if (number >= 31 && number <= 33) {
                    won = (b.value1 == 10);
                } else if (number >= 34 && number <= 36) {
                    won = (b.value1 == 11);
                }
            } else if (b.betType == 2) //intersection between 4 nos.
            {
                //FILL IN
            } else if (b.betType == 1) {} else if (b.betType == 0) //color
            {
                if (number % 2 == 0) {
                    won = (b.value1 == 0);
                } else if (number % 2 != 0) {
                    won = (b.value1 == 1);
                }
            }
            console.log("won", won);
            console.log("number", number);
            console.log("bettype", b.betType);
            console.log("sender", b.player);
            if (won) {
                winnings[b.player] += b.amt;
                console.log("winnings", winnings[b.player]);
                totalBetAmt -= b.amt;
            }
        }
        for (uint256 i = 0; i < bets.length; i++) {
            Bet memory b = bets[i];
            win(b.player);
        }
        delete bets;

        if (totalBetAmt > 0) {
            profit();
        }
    }

    function win(address player) public {
        address payable playerpay = payable(player);
        uint256 amount = winnings[player];
        console.log("player", player);
        console.log("amt", amount);
        if (amount > 0)
            //require(amount<=addres(this).balance);
            playerpay.transfer(amount);
        winnings[player] = 0;
    }

    function profit() internal {
        // uint256 amount=address(this).balance - totalBetAmt;
        uint256 amount = totalBetAmt;
        address payable selfpay = payable(creator);
        if (amount > 0) selfpay.transfer(amount);
    }

    function getThePrice() public view returns (int) {
        (
            , 
            int price,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return price;
    }

    function entranceFee() public view returns (uint256) {
        int min_required = 10; // minimum required in USD, 10$
        int _price = getThePrice()/10**8 ; // price of 1 ether in USD// 
        int min=(10**18 * min_required/_price); //10$/price of 1 eth * 10^18 to convert to wei 
        uint256 min2=uint256(min);
        return min2;

    }

    function startGame() public {
        require(gameState == GameState.CLOSED, "Sorry! Game is closed! ");
        gameState = GameState.OPEN;
    }

    function endGame() public {
        require(gameState == GameState.OPEN, "Sorry! Game is open! ");
        gameState = GameState.CLOSED;
    }
}
