// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * ERC-20 Smart-Contract to mint an ERC-20 token that'll be used for the payment to buy and trade the TICKET(ERC-721).
 * Name of ERC-20 token is Token, and ticker is TKN.
 * MUST BE DEPLOYED BEFORE DEPLOYING TICKETCONTRACT.
 */
contract TokenContract is ERC20 {
    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}   