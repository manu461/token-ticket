// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title A fungible currency token TKN
 * @author Manu Rastogi
 * @notice ERC-20 Smart-Contract to mint an ERC-20 token that'll be used for the payment to buy and trade the TICKET(ERC-721).
 * @notice Name of ERC-20 token is Token, and ticker is TKN.
 * @notice MUST BE DEPLOYED BEFORE DEPLOYING TICKETCONTRACT.
 */
contract TokenContract is ERC20 {
    /**
     * @notice The constructor for the fungible currency token.
     * @notice The supply is hard-coded and not injected via constructor.
     */
    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 10000000000 * 10**decimals());
    }
}
