# BetCoin Smart Contract

This repository contains the smart contract for BetCoin, a decentralized betting platform built on the Binance Smart Chain (BSC). This contract combines a BEP-20 token implementation with a comprehensive betting system, allowing users to create events, place bets, and receive rewards.

## Table of Contents

- [BEP-20 Token](#bep-20-token)
  - [Token Details](#token-details)
  - [Functions](#functions)
- [Betting Platform](#betting-platform)
  - [Events](#events)
  - [Variables](#variables)
  - [Functions](#functions-1)
- [Deployment and Initialization](#deployment-and-initialization)

## BEP-20 Token

BetCoin utilizes a standard BEP-20 token, which is a blueprint for fungible tokens on the Binance Smart Chain. This ensures compatibility with the broader BSC ecosystem.

### Token Details

- **Name**: Customizable during deployment (e.g., "BetCoin")
- **Symbol**: Customizable during deployment (e.g., "BET")
- **Decimals**: Customizable during deployment (e.g., 18)
- **Total Supply**: Customizable during deployment

### Functions

- `totalSupply()`: Returns the total supply of tokens.
- `balanceOf(account: address)`: Returns the token balance of a given account.
- `transfer(recipient: address, amount: uint256)`: Transfers tokens from the caller's account to a recipient.
- `allowance(owner: address, spender: address)`: Returns the amount of tokens that an owner has approved a spender to spend.
- `approve(spender: address, amount: uint256)`: Approves a spender to spend a specified amount of tokens on behalf of the caller.
- `transferFrom(sender: address, recipient: address, amount: uint256)`: Transfers tokens from one account to another using the allowance mechanism.

## Betting Platform

This section describes the core betting functionality of the BetCoin contract.

### Events

- `EventCreate`: Emitted when a new betting event is created.
  - `validator`: The address of the event creator.
  - `eventCode`: A unique identifier for the event.
  - `eventName`: The name of the event.
- `Bet`: Emitted when a user places a bet on an event.
  - `person`: The address of the bettor.
  - `eventCode`: The unique identifier of the event.
  - `decision`: The bettor's chosen outcome (e.g., 'A', 'B', 'C').
  - `amount`: The amount of tokens bet.
- `EventDecision`: Emitted when a validator makes a decision for an event.
  - `eventCode`: The unique identifier of the event.
  - `decision`: The final outcome chosen by the validator.
  - `losers`: The total amount of tokens lost by incorrect bets.

### Variables

- `teamLockedTokens`, `marketingLockedTokens`, `presaleLockedTokens`, `airdropLockedTokens`, `otherLockedTokens`: Amounts of tokens reserved for specific purposes.
- `teamAddress`, `marketingAddress`: Designated addresses for team and marketing token distributions.
- `lastUnlockDate_Team`, `lastUnlockDate_Marketing`: Timestamps of the last token unlocks for team and marketing.
- `unlockTime_Team`, `unlockTime_Marketing`: Constant time periods required for unlocking tokens.
- `unlocksCount_Team`, `unlocksCount_Marketing`: Number of times tokens have been unlocked.
- `contractCreateTime`: The timestamp when the contract was deployed.
- `airdropReceived`: A mapping to track if an address has received an airdrop.
- `airDropMembersLimit`, `airdropMembersCount`: Limits and counts for airdrop participants.
- `MAX_COUNT`: Maximum number of events/bets possible.
- `A_range`, `B_range`, `C_range`: Ranges used for organizing bets by decision.
- `eventsList`: A mapping of `eventCode` to `BetEvent` structs, storing details of all betting events.
- `eventOf`: A mapping to track events created by a specific address.
- `eventOfCount`: A mapping to track the number of events created by an address.
- `betList`: A complex mapping to store individual bids for each event and decision.
- `betOf`: A mapping to store a user's bet details for a specific event and decision.
- `betOfCount`: A mapping to track the total number of bets made by a user.
- `biggestEvents`: A dynamic array to store the top 5 events by weight (total bet amount).
- `feeAddress_1`, `feeAddress_2`: Addresses for collecting fees.

### Structs

- `Bid`:
  - `participant`: Address of the bettor.
  - `amount`: Amount of tokens bet.
- `BetEvent`:
  - `eventCode`: Unique identifier.
  - `auditAddress`: Address of the event creator.
  - `name`: Name of the event.
  - `createTime`, `betTime`, `endTime`: Timestamps for event creation, betting cut-off, and event conclusion.
  - `decision`: The final outcome of the event.
  - `A_weight`, `B_weight`, `C_weight`: Total weight (amount) bet on each decision.
  - `A_name`, `B_name`, `C_name`: Names of the decision options.
  - `A_count`, `B_count`, `C_count`: Number of bets on each decision.
  - `ended`: Boolean indicating if the event has concluded.
  - `weight`: Total amount bet on the event.

### Functions

- `getTime()`: Internal view function to get the current block timestamp.
- `eventCreate(_name: String[100], _bTime: uint256, _endTime: uint256, _aName: String[50], _bName: String[50], _cName: String[50])`: Allows a user to create a new betting event.
- `bet(_eventCode: bytes32, _decision: String[1], _amount: uint256)`: Allows a user to place a bet on an existing event with a chosen decision and amount.
- `sortByWeight(arr: DynArray[bytes32, 5])`: Internal function to sort events by their total weight (used for `biggestEvents`).
- `rebuildEventOf(_from: address, index: uint256)`: Internal function to rebuild the `eventOf` array after removing an event.
- `eventDecision(_eventCode: bytes32, _decision: String[1])`: Allows the event validator to set the final decision for an event, distribute winnings, and collect fees.
- `cancelBid(_eventCode: bytes32, _decision: String[1])`: Allows a user to cancel their bet before the betting time ends or if the event has not concluded yet.
- `unlock()`: Allows the team and marketing addresses to unlock a portion of their reserved tokens over time.
- `sendOther(_receiver: address, _amount: uint256)`: Allows the owner to send tokens from the `otherLockedTokens` pool.
- `sendPresale(_receiver: address, _amount: uint256)`: Allows the owner to send tokens from the `presaleLockedTokens` pool.
- `getAirdrop()`: Allows eligible users to claim airdrop tokens if they meet the criteria.

## Deployment and Initialization

The contract is initialized with the following parameters:

- `_name`: The name of the token.
- `_symbol`: The symbol of the token.
- `_decimals`: The number of decimal places for the token.
- `_supply`: The initial total supply of the token.
- `_teamAddress`: The address designated for team token distribution.
- `_marketingAddress`: The address designated for marketing token distribution.

Upon deployment, a portion of the initial supply is allocated to the deployer, team, marketing, presale, airdrop, and other locked token pools. Token unlocks for team and marketing are time-locked and can be claimed periodically.
