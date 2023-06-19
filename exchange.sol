// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './token.sol';
import "hardhat/console.sol";


contract TokenExchange is Ownable {
    address tokenAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    Token public token = Token(tokenAddr);                                

    // Liquidity pool for the exchange
    uint private token_reserves = 0;
    uint private eth_reserves = 0;

    mapping(address => uint) private lps; 
     
    // Needed for looping through the keys of the lps mapping
    address[] private lp_providers;                     

    // liquidity rewards
    uint private swap_fee_numerator = 3;                
    uint private swap_fee_denominator = 100;

    // Constant: x * y = k
    uint private k;

    // To prevent reentrancy attacks
    uint private denominator = 10 ** 10;
    bool private locked = false;

    constructor() {}
    

    // Function createPool: Initializes a liquidity pool between your Token and ETH.
    // ETH will be sent to pool in this transaction as msg.value
    // amountTokens specifies the amount of tokens to transfer from the liquidity provider.
    // Sets up the initial exchange rate for the pool by setting amount of token and amount of ETH.
    function createPool(uint amountTokens)
        external
        payable
        onlyOwner
    {
        // require pool does not yet exist:
        require (token_reserves == 0, "Token reserves was not 0");
        require (eth_reserves == 0, "ETH reserves was not 0.");

        // require nonzero values were sent
        require (msg.value > 0, "Need eth to create pool.");
        uint tokenSupply = token.balanceOf(msg.sender);
        require(amountTokens <= tokenSupply, "Not have enough tokens to create the pool");
        require (amountTokens > 0, "Need tokens to create pool.");

        token.transferFrom(msg.sender, address(this), amountTokens);
        token_reserves = token.balanceOf(address(this));
        eth_reserves = msg.value;
        k = token_reserves * eth_reserves;
    }

    // Function removeLP: removes a liquidity provider from the list.
    // This function also removes the gap left over from simply running "delete".
    function removeLP(uint index) private {
        require(index < lp_providers.length, "specified index is larger than the number of lps");
        lp_providers[index] = lp_providers[lp_providers.length - 1];
        lp_providers.pop();
    }

    // Function getSwapFee: Returns the current swap fee ratio to the client.
    function getSwapFee() public view returns (uint, uint) {
        return (swap_fee_numerator, swap_fee_denominator);
    }

    
    /* ========================= Liquidity Provider Functions =========================  */ 

    // Function addLiquidity: Adds liquidity given a supply of ETH (sent to the contract as msg.value).
    // You can change the inputs, or the scope of your function, as needed.
    function addLiquidity(uint max_exchange_rate, uint min_exchange_rate) 
        external 
        payable
    {
        // Amount of ETH and tokens to add to the pool
        uint eth_value = msg.value;
        uint token_value = eth_value * token_reserves / eth_reserves;

        // Check positive amount of liquidity, exchange rate is in range, and user has enough tokens
        require(eth_value > 0, "Eth value must be > 0");
        require(eth_reserves <= max_exchange_rate * token_reserves && eth_reserves >= min_exchange_rate * token_reserves, "Exchange rate is not in range");
        require(token_value <= token.balanceOf(msg.sender), "Trying to add more tokens than you have");

        // Add tokens to the pool
        token.transferFrom(msg.sender, address(this), token_value);

        // Update exchange values
        uint orig_reserves = token_reserves;
        token_reserves = token.balanceOf(address(this));
        eth_reserves = address(this).balance;
        k = token_reserves * eth_reserves;

        // Update lps
        bool oldUser = false;
        for (uint i = 0; i < lp_providers.length; i++) {
            if (lp_providers[i] == msg.sender) {
                oldUser = true;
                lps[lp_providers[i]] = (lps[lp_providers[i]] * orig_reserves + token_value * denominator) / token_reserves;
                return;
            } else {
                lps[lp_providers[i]] = lps[lp_providers[i]] * orig_reserves / token_reserves;
            }
        }

        // Add new user to lp_providers
        if (!oldUser) {
            lp_providers.push(msg.sender);
            lps[msg.sender] = token_value * denominator / token_reserves;
        }
    }


    // Function removeLiquidity: Removes liquidity given the desired amount of ETH to remove.
    // You can change the inputs, or the scope of your function, as needed.
    function removeLiquidity(uint amountETH, uint max_exchange_rate, uint min_exchange_rate)
        public 
        payable
    {
        // Lock function to prevent reentrancy attacks
        require(!locked);
        locked = true;

        // Amount of tokens to remove from the pool
        uint amountTokens = amountETH * token_reserves / eth_reserves;

        // Check positive amount of liquidity, exchange rate is in range, user has enough tokens, and there is enough liquidity
        require(amountETH > 0, "Amount of ETH to remove must be > 0");
        require(eth_reserves <= max_exchange_rate * token_reserves && eth_reserves >= min_exchange_rate * token_reserves, "Exchange rate is not in range");
        require(amountTokens <= token.balanceOf(msg.sender), "Trying to remove more tokens than you have");
        require(token_reserves - amountTokens > 0 && eth_reserves - amountETH > 0, "Not enough liquidity to remove");

        // Send ETH and tokens
        payable(msg.sender).transfer(amountETH);
        token.transfer(msg.sender, amountTokens);

        // Update exchange values
        uint orig_reserves = token_reserves;
        token_reserves = token.balanceOf(address(this));
        eth_reserves = address(this).balance;
        k = token_reserves * eth_reserves;

        // Update lps
        uint sender_index = 0;
        for (uint i = 0; i < lp_providers.length; i++) {
            if (lp_providers[i] == msg.sender) {
                lps[lp_providers[i]] = (lps[lp_providers[i]] * orig_reserves - amountTokens * denominator) / token_reserves;
                sender_index = 0;
            } else {
                lps[lp_providers[i]] = lps[lp_providers[i]] * orig_reserves / token_reserves;
            }
        }

        // Remove user from lp_providers if no more stake
        if (lps[msg.sender] == 0) {
            removeLP(sender_index);
        }

        locked = false;
    }

    // Function removeAllLiquidity: Removes all liquidity that msg.sender is entitled to withdraw
    // You can change the inputs, or the scope of your function, as needed.
    function removeAllLiquidity(uint max_exchange_rate, uint min_exchange_rate)
        external
        payable
    {
        // Calculate tokens to remove, ensuring not emptying reserves
        uint tokensToRemove = lps[msg.sender] * token_reserves / denominator;
        if (token_reserves - tokensToRemove < 1) {
            tokensToRemove -= 1;
        }

        // Calculate corresponding ETH to remove, ensuring not emptying reserves
        uint ethToRemove = tokensToRemove * eth_reserves / token_reserves;
        if (eth_reserves - ethToRemove < 1) {
            ethToRemove -= 1;
        }

        removeLiquidity(ethToRemove, max_exchange_rate, min_exchange_rate);
    }


    /* ========================= Swap Functions =========================  */ 

    // Function swapTokensForETH: Swaps your token with ETH
    // You can change the inputs, or the scope of your function, as needed.
    function swapTokensForETH(uint amountTokens, uint max_exchange_rate)
        external 
        payable
    {
        // Lock function to prevent reentrancy attacks
        require(!locked);
        locked = true;

        // Amount of ETH that tokens can be swapped for
        uint amountETH = eth_reserves - (k / (token_reserves + amountTokens));
        uint fees = amountETH * swap_fee_numerator / swap_fee_denominator;
        amountETH -= fees;
        
        // Check positive amount of liquidity, exchange rate is in range, user has enough tokens, and there is enough liquidity
        require(amountTokens > 0, "Must swap positive amount of tokens");
        require(eth_reserves <= max_exchange_rate * token_reserves, "Exchange rate is not in range");
        require(amountTokens <= token.balanceOf(msg.sender), "Trying to remove more tokens than you have");
        require(eth_reserves - amountETH >= 1, "Not enough ETH reserves to swap");

        // Make swap
        token.transferFrom(msg.sender, address(this), amountTokens);
        payable(msg.sender).transfer(amountETH);

        // Update exchange values
        token_reserves = token.balanceOf(address(this));
        eth_reserves = address(this).balance;

        locked = false;
    }



    // Function swapETHForTokens: Swaps ETH for your tokens
    // ETH is sent to contract as msg.value
    // You can change the inputs, or the scope of your function, as needed.
    function swapETHForTokens(uint max_exchange_rate)
        external
        payable 
    {
        // Lock function to prevent reentrancy attacks
        require(!locked);
        locked = true;

        // Amount of tokens that ETH can be swapped for
        uint amountTokens = token_reserves - (k / (eth_reserves + msg.value));
        uint fees = amountTokens * swap_fee_numerator / swap_fee_denominator;
        amountTokens -= fees;

        // Check positive amount of liquidity, exchange rate is in range, user has enough tokens, and there is enough liquidity
        require(msg.value > 0, "Must swap positive amount of ETH");
        require(eth_reserves <= max_exchange_rate * token_reserves, "Exchange rate is not in range");
        require(token_reserves - amountTokens >= 1, "Not enough Token reserves to swap");

        // Make swap
        token.transfer(msg.sender, amountTokens);

        // Update exchange values
        token_reserves = token.balanceOf(address(this));
        eth_reserves = address(this).balance;

        locked = false;
    }
}