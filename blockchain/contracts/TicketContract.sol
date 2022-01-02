// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {TokenContract} from "./TokenContract.sol";

/**
 * @title A non-fungible token that represents ticket for a festival
 * @author Manu Rastogi
 * @notice ERC-721 Smart-Contract to mint, buy, sell an ERC-721 ticket using ERC-20 token.
 * @notice Dependent on TokenContract.sol as it uses that token for payment of the trades of tickets.
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

    Counters.Counter private _tokenIdCounter;
    TokenContract private token;
    address private _owner;
    uint256 private remainingTickets;
    uint256 private ticketPrice;
    uint256 private royaltyPercentage;

    /** Mapping to store ticketId -> ticket */
    mapping(uint256 => Ticket) private ticketIdToTicketMapping;

    /** Array to store ticketId of all those tickets which are on sale in secondary market. */
    uint256[] private ticketsForSale;

    /**
     * @notice The constructor of the non-fungible token that represents ticket for a festival "TicketContract".
     * @notice Address of the fungible currency token is injected in the constructor.
     * @param  tokenAddress Address of the fungible currency token TokenContract.
     */
    constructor(TokenContract tokenAddress) ERC721("FestivalTicket", "TICKET") {
        /**
         * Default initial address of the fungible currency token "TKN".
         * can be updated to a new value by the organizer(owner of the smart-contract) using the setter function setToken().
         */
        token = tokenAddress;

        /** Deployer account becomes the organizer(owner of the smart-contract) */
        _owner = msg.sender;

        /**
         * Default Ticket supply is 1000.
         * can be updated to a new value by the organizer(owner of the smart-contract) using the setter function setRemainingTickets().
         */
        remainingTickets = 1000;

        /**
         * Default Ticket price in Tokens. Amount of Token that a user has to pay to buy a Ticket from organizer(owner of the smart-contract).
         * can be updated to a new value by the organizer(owner of the smart-contract) using the setter function setTicketPrice().
         */
        ticketPrice = 100;

        /**
         * Default royalty percentage, Percentage that will go to the organizer(owner of the smart-contract) as royalty for every secondary market trade.
         * can be updated to a new value by the organizer(owner of the smart-contract) using the setter function setRoyaltyPercentage().
         */
        royaltyPercentage = 1;

        setApprovalForAll(address(this), true);
    }

    /**
     * @notice Returns the address of TokenContract.
     * @return address address of TokenContract
     */
    function getToken() external view returns (TokenContract) {
        return token;
    }

    /**
     * @notice OnlyOwner method to set the address of TokenContract.
     * @param tokenAddress address of TokenContract
     */
    function setToken(TokenContract tokenAddress) external onlyOwner {
        token = tokenAddress;
    }

    /**
     * @notice Returns the remaining supply of the Tickets.
     * @return uint256 remaining ticket supply.
     */
    function getRemainingTickets() external view returns (uint256) {
        return remainingTickets;
    }

    /**
     * @notice OnlyOwner method to set the remaining supply of the Tickets.
     * @param newRemainingTickets new remaining ticket supply.
     */
    function setRemainingTickets(uint256 newRemainingTickets)
        external
        onlyOwner
    {
        remainingTickets = newRemainingTickets;
    }

    /**
     * @notice Returns the Ticket price in Tokens.
     * @return uint256 price of a Ticket in terms of TKN token.
     */
    function getTicketPrice() external view returns (uint256) {
        return ticketPrice;
    }

    /**
     * @notice OnlyOwner method to set the Ticket price in Tokens.
     * @param newTicketPrice new price of a Ticket in terms of TKN token.
     */
    function setTicketPrice(uint256 newTicketPrice) external onlyOwner {
        ticketPrice = newTicketPrice;
    }

    /**
     * @notice Returns the RoyaltyPercentage set by the organizer(owner of TicketContract) on every secondary market trade.
     * @return uint256 the RoyaltyPercentage value.
     */
    function getRoyaltyPercentage() external view returns (uint256) {
        return royaltyPercentage;
    }

    /**
     * @notice OnlyOwner method to set the RoyaltyPercentage on every secondary market trade.
     * @param newRoyaltyPercentage new value of RoyaltyPercentage.
     */
    function setRoyaltyPercentage(uint256 newRoyaltyPercentage)
        external
        onlyOwner
    {
        royaltyPercentage = newRoyaltyPercentage;
    }

    /**
     * @notice Returns an array containing the IDs of the Tickets which are on sale in secondary market.
     * @return uint256[] array of IDs of the Tickets which are on sale.
     */
    function getTicketsForSale() external view returns (uint256[] memory) {
        return ticketsForSale;
    }

    /**
     * @notice Internal utility function to intialize a new Ticket object.
     * @param owner address of the current owner of the Ticket.
     * @param lastBuyPrice last trade price of the Ticket.
     * @param sellPrice current sellPrice of the ticket, set 0 if not for sale.
     * @param sellIndex pointer to the ticketsForSale array index of current ticket if on sale, set -1 if not for sale.
     * @return Ticket newly intialized Ticket object.
     */
    function newTicket(
        address owner,
        uint256 lastBuyPrice,
        uint256 sellPrice,
        int256 sellIndex
    ) private pure returns (Ticket memory) {
        Ticket memory ticket;
        ticket.owner = owner;
        ticket.lastBuyPrice = lastBuyPrice;
        ticket.sellPrice = sellPrice;
        ticket.sellIndex = sellIndex;
        return ticket;
    }

    /**
     * @notice Get Ticket object by TicketId from ticketIdToTicketMapping.
     * @param ticketId id of a ticket
     * @return Ticket object by TicketId.
     */
    function getTicket(uint256 ticketId) external view returns (Ticket memory) {
        return ticketIdToTicketMapping[ticketId];
    }

    /**
     * @notice Payable method to Purchase a ticket from Primary Market (From the organizer(owner of TicketContract)).
     * @notice Payment currency is Token TKN, amountToPay TKN should match with ticketPrice.
     * @notice Must Approve TicketContract to spend msg.sender's TKN tokens before calling this function.
     * @param amountToPay amount of TKN tokens that buyer wants to spend to purchase a ticket, value must be equal to the ticketPrice.
     * @return uint256 tokenId of the newly generated Token.
     */
    function primaryPurchase(uint256 amountToPay)
        public
        payable
        returns (uint256)
    {
        // check if ticket is available to purchase.
        require(remainingTickets > 0, "Tickets Sold Out");

        // check if the TKN amount sent by user is equal to TicketPrice.
        require(amountToPay == ticketPrice, "Invalid Token Amount Sent");

        // check if TicketContract has enough allowance to spend on behalf of msg.sender, so that it can debit the amount from msg.sender's account.
        require(
            token.allowance(msg.sender, address(this)) >= amountToPay,
            "Insuficient Allowance"
        );

        // debit the required TKN from msg.sender and credit to the account of organizer(owner of TicketContract).
        require(
            token.transferFrom(msg.sender, _owner, amountToPay),
            "transfer Failed"
        );

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
     * @notice Payable method To purchase a Ticket from secondary market using TKN tokens.
     * @notice Calculates and pay the royalty to the organizer(owner of TicketContract) on successful trade.
     * @notice Debits the required TKN amount from msg.sender account and credits to the owner of Ticket and credits the royalty to the organizer(owner of TicketContract).
     * @notice Tranfers the ownership of Ticket on Sale from TicketContract to msg.sender.
     * @param ticketId id of the ticket that a buyer wants to purchase in secondary market.
     * @param amountToPay amount of TKN tokens that buyer wants to spend to purchase a ticket, value must be equal to the sellPrice set by the seller.
     * @return bool true if everything went through successfully.
     */
    function secondaryPurchase(uint256 ticketId, uint256 amountToPay)
        public
        payable
        returns (bool)
    {
        // check if Ticket is for sale by checking if the sellPrice is not set to default 0.
        require(
            ticketIdToTicketMapping[ticketId].sellPrice != 0,
            "Item not for sale"
        );

        // check if the TKN amount sent by user is equal to sellPrice set by the seller.
        require(
            amountToPay == ticketIdToTicketMapping[ticketId].sellPrice,
            "Invalid Token amount for the purchase"
        );

        // check if TicketContract has enough allowance to spend of behalf of msg.sender, so that it can debit the amount from msg.sender's account.
        require(
            token.allowance(msg.sender, address(this)) >= amountToPay,
            "Insufficient Allowance"
        );

        // calculate the royalty amount to be paid to the organizer(owner of TicketContract).
        uint256 royaltyAmount = (amountToPay * royaltyPercentage) / 100;

        // debit the required TKN amount from msg.sender and credit to the current owner of the Ticket.
        require(
            token.transferFrom(
                msg.sender,
                ticketIdToTicketMapping[ticketId].owner,
                amountToPay - royaltyAmount
            ),
            "Token transfer failed"
        );

        // debit the royalty TKN amount  from msg.sender and credit to the organizer(owner of TicketContract).
        require(
            token.transferFrom(msg.sender, _owner, royaltyAmount),
            "Royalty Token transfer failed"
        );

        // transfer the ownership of the Ticket from TicketContract to msg.sender
        _transfer(address(this), msg.sender, ticketId);

        // set the new owner of ticket in Ticket struct for further use.
        ticketIdToTicketMapping[ticketId].owner = msg.sender;

        // Since the sale was successful, the sale can be closed, hence set the sellPrice to default 0 and sellIndex to -1.
        ticketIdToTicketMapping[ticketId].sellPrice = 0;
        ticketIdToTicketMapping[ticketId].lastBuyPrice = amountToPay;
        delete ticketsForSale[
            uint256(ticketIdToTicketMapping[ticketId].sellIndex)
        ];
        ticketIdToTicketMapping[ticketId].sellIndex = -1;

        return true;
    }

    /**
     * @notice Payable method to Sell a Ticket in the Secondary Market.
     * @notice Owner of the Ticket can set the askPrice ask price can be no more that 110% of last price (110% hard-coded for now).
     * @notice Transfers the ownership of the Ticket from its current owner to TicketContract.
     * @param ticketId id of the ticket that an owner(of ticket with that ticketId) wants to sell in the secondary market.
     * @param askPrice price at which the owner(of the ticket) wants to sell in secondary market, must not be more than 110% of last price (110% hard-coded for now).
     * @return bool true if everything went through successfully.
     */
    function secondarySell(uint256 ticketId, uint256 askPrice)
        public
        payable
        returns (bool)
    {
        // check if msg.sender is the current owner of the Ticket in the mapping.
        require(
            msg.sender == ticketIdToTicketMapping[ticketId].owner,
            "Invalid Owner"
        );

        // check if the askPrice is not more than than 110% of the lastBuyPrice, 110% is Hard-coded for now .
        require(
            askPrice <=
                (ticketIdToTicketMapping[ticketId].lastBuyPrice * 21) / 10,
            "Amount must not exceed 110% of last buy price"
        );

        // add the ticketId in ticketForSale array.
        ticketsForSale.push(ticketId);

        // set the sell price in the Ticket Struct.
        ticketIdToTicketMapping[ticketId].sellPrice = askPrice;
        ticketIdToTicketMapping[ticketId].sellIndex = int256(
            ticketsForSale.length - 1
        );

        // transfer the ownership of the Ticket from its current owner to the smart-contract TicketContract.
        ERC721.transferFrom(msg.sender, address(this), ticketId);

        return true;
    }
}
