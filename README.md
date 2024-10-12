# Donor Glee Fund & Raffle

## Overview

The Donor Glee Fund is a smart contract system that allows users to create donation campaigns and manage funds. It incorporates a raffle system to incentivize donations. The system is designed to facilitate transparent fundraising, allowing donors to contribute while providing a chance to win rewards through a raffle.

### Contracts

1. **DonorGleeFund**
2. **DonorGleeRaffle**

## DonorGleeFund

### Description

The `DonorGleeFund` contract manages donations, including creation, funding, and withdrawal of funds. It also manages a whitelist for wallets, expiration of donation campaigns, and integration with the raffle system.

### Features

- Create donation campaigns
- Fund donations with ETH
- Withdraw funds by the creator of the donation
- Manage whitelisted wallets for promotional benefits
- Automatically expire donations after a set time
- Integrate with `DonorGleeRaffle` for prize distribution

### Functions

- `createDonation(string memory _name, string memory _description, address _walletAdd, uint256 _goal, uint256 _activeTime)`
- `fundDonation(uint256 donationId)`
- `redeemDonation(uint256 donationId)`
- `fundPlatformCreator()`
- `reedeemPlatformCreatorFunds()`
- `addWalletToWhiteList(address wallet)`
- `removeWalletFromWhiteList(address wallet)`
- `closeExpireDonations()`
- `checkUpkeep(bytes memory /*checkData*/ )`
- `performUpkeep(bytes calldata /*performData*/ )`

### Errors

- `DonorGleeFund__InvalidAmount`
- `DonorGleeFund__InvalidAddress`
- `DonorGleeFund__InvalidDonation`
- `DonorGleeFund__InvalidActiveTime`
- `DonorGleeFund__TransferFailed`
- `DonorGleeFund__IllegealAccessToDonation`
- `DonorGleeFund__DonationSessionIsExpired`
- `DonorGleeFund__AccessToRaffleContractStateFailed`
- `DonorGleeFund__NoUpkeepNeeded`

### Events

- `DonationCreated`
- `DonationRaised`
- `DonationWithdrawn`
- `WalletWhiteListed`
- `WalletRemovedFromWhiteList`
- `DonationExpired`
- `PlatformFunded`
- `PlatformFundWithDrawed`

## DonorGleeRaffle

### Description

The `DonorGleeRaffle` contract handles the raffle process, allowing players to enter raffles and managing the prize distribution using Chainlink VRF for randomness.

### Features

- Enter raffles with ETH
- Automatically select a winner after a predefined interval
- Integrate with Chainlink VRF for secure random number generation

### Functions

- `enterRaffle(address[] memory newPlayers)`
- `checkUpkeep(bytes memory /*checkData*/ )`
- `performUpkeep(bytes calldata /*performData*/ )`
- `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`

### Errors

- `DonorGleeRaffle__RaffleIsCALCULATING`
- `DonorGleeRaffle__NoUpkeepNeeded`
- `DonorGleeRaffle__TransferFailed`

### Events

- `RaffleEntered`
- `WinnerRequsted`
- `WinnerPlayerDeclared`

## Usage

### Deployment

To deploy these contracts, you need a compatible Ethereum environment (e.g., Remix, Truffle, Hardhat) with the appropriate dependencies installed:

- OpenZeppelin Contracts
- Chainlink VRF

### Running the Raffle

1. Deploy `DonorGleeFund` with the required parameters.
2. Deploy `DonorGleeRaffle` with VRF parameters.
3. Use the `createDonation` function to start a donation campaign.
4. Fund the campaign and track donations.
5. When conditions are met, call `performUpkeep` to trigger the raffle process.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Author

- **Sohamkumar Prajapati** - [smrp1720@gmail.com](mailto:smrp1720@gmail.com)


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
