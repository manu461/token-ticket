const tokenContract = artifacts.require('TokenContract');
const ticketContract = artifacts.require('TicketContract');

module.exports = function (deployer) {
  deployer.deploy(tokenContract).then(function () {
    return deployer.deploy(ticketContract, tokenContract.address)
  });
};
