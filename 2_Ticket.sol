// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {Token} from "./1_Token.sol";

contract TicketContract is ERC721, Ownable {
    using Counters for Counters.Counter;

    struct Ticket {
        address owner;
        uint256 lastBuyPrice;
        uint256 sellPrice;
        int256 sellIndex;
    }

    Counters.Counter            private     _tokenIdCounter;
    Token                       private     token;
    address                     private     _owner;
    uint256                     private     remainingTickets;
    uint256                     private     ticketPrice;
    mapping(uint256 => Ticket)  private     ticketIdToTicketMapping;
    uint256[]                   private     ticketsForSale;
    

    constructor(Token tokenAddress) ERC721("ON", "ONFT") {
        token = tokenAddress;
        _owner = msg.sender;
        remainingTickets  = 1000;
        ticketPrice = 10;
        setApprovalForAll(address(this), true);
    }

    function getToken() external view returns (Token) {
        return token;
    }

    function setToken(Token tokenAddress) onlyOwner external {
        token = tokenAddress;
    }

    function getRemainingTickets() external view returns (uint256) {
        return remainingTickets;
    }

    function setRemainingTickets(uint256 newRemainingTickets) onlyOwner external {
        remainingTickets = newRemainingTickets;
    }

    function getTicketPrice() external view returns (uint256) {
        return ticketPrice;
    }

    function setTicketPrice(uint256 newTicketPrice) onlyOwner external {
        ticketPrice = newTicketPrice;
    }

    function getTicketsForSale() external view returns (uint256[] memory) {
        return ticketsForSale;
    }

    function newTicket(address owner, uint256 lastBuyPrice, uint256 sellPrice, int256 sellIndex) private pure returns(Ticket memory) {
        Ticket memory ticket;
        ticket.owner = owner;
        ticket.lastBuyPrice = lastBuyPrice;
        ticket.sellPrice = sellPrice;
        ticket.sellIndex = sellIndex;
        return ticket;
    }

    function getTicket(uint256 ticketId) external view returns (Ticket memory) {
        return ticketIdToTicketMapping[ticketId];
    }

    function primaryPurchase(uint256 amountToPay) public payable returns (uint256) {
        require(remainingTickets > 0, "Tickets Sold Out");
        require(amountToPay == ticketPrice, "Invalid Token Amount Sent");
        require(token.allowance(msg.sender, address(this)) >= amountToPay,"Insuficient Allowance");
        require(token.transferFrom(msg.sender, _owner, amountToPay),"transfer Failed");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        remainingTickets--;
        Ticket memory ticket = newTicket(msg.sender, amountToPay, 0, -1);
        ticketIdToTicketMapping[tokenId] = ticket;
        return tokenId;
    }

    function secondaryPurchase(uint256 ticketId, uint256 amountToPay) public payable returns (bool) {
        require(ticketIdToTicketMapping[ticketId].sellPrice != 0, "Item not for sale");
        require(amountToPay == ticketIdToTicketMapping[ticketId].sellPrice, "Invalid Token amount for the purchase");
        require(token.allowance(msg.sender, address(this)) >= amountToPay, "Insufficient Allowance");
        require(token.transferFrom(msg.sender, ticketIdToTicketMapping[ticketId].owner, amountToPay), "Token transfer failed");
        _transfer(address(this), msg.sender, ticketId);
        ticketIdToTicketMapping[ticketId].owner = msg.sender;
        ticketIdToTicketMapping[ticketId].sellPrice = 0;
        delete ticketsForSale[uint256(ticketIdToTicketMapping[ticketId].sellIndex)];
        ticketIdToTicketMapping[ticketId].sellIndex = -1;
        return true;
    }

    function secondarySell(uint256 ticketId, uint256 askPrice) public payable returns (bool) {
        require(msg.sender == ticketIdToTicketMapping[ticketId].owner, "Invalid");
        require(askPrice <= ticketIdToTicketMapping[ticketId].lastBuyPrice*21/10, "Amount must not exceed 110% of last buy price");
        ticketsForSale.push(ticketId);
        ticketIdToTicketMapping[ticketId].sellPrice = askPrice;
        ticketIdToTicketMapping[ticketId].sellIndex = int256(ticketsForSale.length-1);
        ERC721.transferFrom(msg.sender, address(this), ticketId);
        return true;
    }

}