// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenContract is ERC20 {
    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}   