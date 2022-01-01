// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {TokenContract} from "./TokenContract.sol";

/**
 * ERC-721 Smart-Contract to mint, buy, sell an ERC-721 ticket using ERC-20 token.
 * Dependent on TokenContract.sol as it uses that token for payment of the trades of tickets.
 */
contract TicketContract is ERC721, Ownable {

    /** Ticket id generator -> sequential and starts from value 0 */
    using Counters for Counters.Counter;

    /** Struct to store crucial information about a ticket. */
    struct Ticket {
        address owner;
        uint256 lastBuyPrice;
        uint256 sellPrice;
        int256 sellIndex;
    }

    Counters.Counter            private     _tokenIdCounter;
    TokenContract               private     token;
    address                     private     _owner;
    uint256                     private     remainingTickets;
    uint256                     private     ticketPrice;
    uint256                     private     royaltyPercentage;

    /** Mapping to store ticketId -> ticket */
    mapping(uint256 => Ticket)  private     ticketIdToTicketMapping;
    
    /** Array to store ticketId of all those tickets which are on sale in secondary market. */
    uint256[]                   private     ticketsForSale;
    

    constructor(TokenContract tokenAddress) ERC721("NewYear2022FestivalTicket", "TICKET") {
        /** 
         * Default address ERC-20 token that'll be used for payments. 
         * can be updated to a new value by the owner of the smart-contract using the setter function setToken(). 
         */
        token = tokenAddress;

        _owner = msg.sender;

        /** 
         * Default Ticket supply is 1000. 
         * can be updated to a new value by the owner of the smart-contract using the setter function setRemainingTickets().
         */
        remainingTickets = 1000;

        /** 
         * Default Ticket price in Tokens. Amount of Token that a user has to pay to buy a Ticket from owner.
         * can be updated to a new value by the owner of the smart-contract using the setter function setTicketPrice().
         */
        ticketPrice = 10;

        /** 
         * Default royalty percentage, Percentage that will go to the owner as royalty for every secondary market trade.
         * can be updated to a new value by the owner of the smart-contract using the setter function setRoyaltyPercentage().
         */
        royaltyPercentage = 1;

        setApprovalForAll(address(this), true);
    }

    /** Returns the address of TokenContract. */
    function getToken() external view returns (TokenContract) {
        return token;
    }

    /** OnlyOwner method to set the address of TokenContract. */
    function setToken(TokenContract tokenAddress) onlyOwner external {
        token = tokenAddress;
    }

    /** Returns the remaining supply of the Tickets. */
    function getRemainingTickets() external view returns (uint256) {
        return remainingTickets;
    }

    /** OnlyOwner method to set the remaining supply of the Tickets. */
    function setRemainingTickets(uint256 newRemainingTickets) onlyOwner external {
        remainingTickets = newRemainingTickets;
    }

    /** Returns the Ticket price in Tokens. */
    function getTicketPrice() external view returns (uint256) {
        return ticketPrice;
    }

    /** OnlyOwner method to set the Ticket price in Tokens. */
    function setTicketPrice(uint256 newTicketPrice) onlyOwner external {
        ticketPrice = newTicketPrice;
    }

     /** Returns the RoyaltyPercentage set by the owner on every secondary market trade. */
    function getRoyaltyPercentage() external view returns (uint256) {
        return royaltyPercentage;
    }

    /** OnlyOwner method to set the RoyaltyPercentage on every secondary market trade. */
    function setRoyaltyPercentage(uint256 newRoyaltyPercentage) onlyOwner external {
        royaltyPercentage = newRoyaltyPercentage;
    }

    /** Returns an array containing the IDs of the Tickets which are on sale in secondary market. */
    function getTicketsForSale() external view returns (uint256[] memory) {
        return ticketsForSale;
    }

    /** Internal utility function to intialize a new Ticket object. */
    function newTicket(address owner, uint256 lastBuyPrice, uint256 sellPrice, int256 sellIndex) private pure returns(Ticket memory) {
        Ticket memory ticket;
        ticket.owner = owner;
        ticket.lastBuyPrice = lastBuyPrice;
        ticket.sellPrice = sellPrice;
        ticket.sellIndex = sellIndex;
        return ticket;
    }

    /** Get Ticket object by TicketId from ticketIdToTicketMapping. */
    function getTicket(uint256 ticketId) external view returns (Ticket memory) {
        return ticketIdToTicketMapping[ticketId];
    }

    /**
     * Payable method to Purchase a ticket from Primary Market (From the owner).
     * Payment currency is Token TKN, amountToPay TKN should match with ticketPrice.
     * Must Approve TicketContract to spend msg.sender's TKN tokens before calling this function. 
     */
    function primaryPurchase(uint256 amountToPay) public payable returns (uint256) {

        // check if ticket is available to purchase.
        require(remainingTickets > 0, "Tickets Sold Out");

        // check if the TKN amount sent by user is equal to TicketPrice.
        require(amountToPay == ticketPrice, "Invalid Token Amount Sent");

        // check if TicketContract has enough allowance to spend on behalf of msg.sender, so that it can debit the amount from msg.sender's account.
        require(token.allowance(msg.sender, address(this)) >= amountToPay,"Insuficient Allowance");

        // debit the required TKN from msg.sender and credit to owner's account.
        require(token.transferFrom(msg.sender, _owner, amountToPay),"transfer Failed");

        // mint a Ticket for msg.sender
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        // reduce the available Ticket supply by 1.
        remainingTickets--;

        // store information about the generated Ticket for further use.
        Ticket memory ticket = newTicket(msg.sender, amountToPay, 0, -1);
        ticketIdToTicketMapping[tokenId] = ticket;

        return tokenId;
    }

    /**
     * Payable method To purchase a Ticket from secondary market using TKN tokens.
     * Calculates and pay the royalty to the owner on successful trade.
     * Debits the required TKN amount from msg.sender account and credits to the owner of Ticket and credits the royalty to the owner of Contract.
     * Tranfers the ownership of Ticket on Sale from TicketContract to msg.sender.
     */
    function secondaryPurchase(uint256 ticketId, uint256 amountToPay) public payable returns (bool) {
        
        // check if Ticket is for sale by checking if the sellPrice is not set to default 0.
        require(ticketIdToTicketMapping[ticketId].sellPrice != 0, "Item not for sale");

        // check if the TKN amount sent by user is equal to sellPrice set by the seller.
        require(amountToPay == ticketIdToTicketMapping[ticketId].sellPrice, "Invalid Token amount for the purchase");

        // check if TicketContract has enough allowance to spend of behalf of msg.sender, so that it can debit the amount from msg.sender's account.
        require(token.allowance(msg.sender, address(this)) >= amountToPay, "Insufficient Allowance");

        // calculate the royalty amount to be paid to the owner.
        uint256 royaltyAmount = amountToPay * royaltyPercentage / 100;

        // debit the required TKN amount from msg.sender and credit to the current owner of the Ticket.
        require(token.transferFrom(msg.sender, ticketIdToTicketMapping[ticketId].owner, amountToPay-royaltyAmount), "Token transfer failed");
        
        // debit the reyality TKN amount  from msg.sender and credit to the owner of the contract.
        require(token.transferFrom(msg.sender, _owner, royaltyAmount), "Royalty Token transfer failed");

        // transfer the ownership of the Ticket from TicketContract to msg.sender
        _transfer(address(this), msg.sender, ticketId);

        // set the new owner in Ticket struct for further use.
        ticketIdToTicketMapping[ticketId].owner = msg.sender;

        // Since the sale was successful, the sale can be closed, hence set the sellPrice to default 0.
        ticketIdToTicketMapping[ticketId].sellPrice = 0;
        ticketIdToTicketMapping[ticketId].lastBuyPrice = amountToPay;
        delete ticketsForSale[uint256(ticketIdToTicketMapping[ticketId].sellIndex)];
        ticketIdToTicketMapping[ticketId].sellIndex = -1;

        return true;
    }

    /**
     * Payable method to Sell a Ticket in the Secondary Market.
     * Owner of the Ticket can set the askPrice ask price can be no more that 110% of last price (110% hard-coded for now).
     * Transfers the ownership of the Ticket from its current owner to TicketContract.
     */
    function secondarySell(uint256 ticketId, uint256 askPrice) public payable returns (bool) {
        
        // check if msg.sender is the owner of the Ticket.
        require(msg.sender == ticketIdToTicketMapping[ticketId].owner, "Invalid Owner");
        
        // check if the askPrice is not more than than 110% of the lastBuyPrice, 110% is Hard-coded for now .
        require(askPrice <= ticketIdToTicketMapping[ticketId].lastBuyPrice*21/10, "Amount must not exceed 110% of last buy price");

        // add the ticketId in ticketForSale array.
        ticketsForSale.push(ticketId);

        // set the sell price in the Ticket Struct.
        ticketIdToTicketMapping[ticketId].sellPrice = askPrice;
        ticketIdToTicketMapping[ticketId].sellIndex = int256(ticketsForSale.length-1);
        
        // transfer the ownership of the Ticket from its current owner to the TicketContract.
        ERC721.transferFrom(msg.sender, address(this), ticketId);
        
        return true;
    }

}