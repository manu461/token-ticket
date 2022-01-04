# token-ticket

## Contract Deployment
1. RUN `cd token-ticket/blockchain`
2. RUN `ganache-cli`
3. RUN `npm i`
4. RUN `npx truffle console`
5. RUN `build`
6. RUN `migrate`

---
## Call Graph TokenContract
![Call Graph TokenContract](.artifacts/callGraph_tokenContract.svg)


---
## Call Graph TicketContract
![Call Graph TicketContract](.artifacts/callGraph_ticketContract.svg)

## Function Signature TicketContract
```
Sighash   |   Function Signature
========================
15981650  =>  setTicketPrice(uint256)
ed9cf58c  =>  setToken()
ce3c2c1c  =>  setRemainingTickets()
95d29794  =>  setTicketPrice()
8f03d7bf  =>  setRoyaltyPercentage()
21df0da7  =>  getToken()
fd5833e7  =>  setToken(TokenContract)
70cc89ad  =>  getRemainingTickets()
51b8a728  =>  setRemainingTickets(uint256)
87bb7ae0  =>  getTicketPrice()
59c8b7dd  =>  getRoyaltyPercentage()
61ba27da  =>  setRoyaltyPercentage(uint256)
35fe12d8  =>  getTicketsForSale()
3be74950  =>  newTicket(address,uint256,uint256,int256)
7dc379fa  =>  getTicket(uint256)
c3da02bc  =>  primaryPurchase(uint256)
086b5d6d  =>  secondaryPurchase(uint256,uint256)
4f279937  =>  secondarySell(uint256,uint256)
```

---
@Author: Manu Rastogi