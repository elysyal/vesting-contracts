# TOKEN Vesting Smart Contract

This repository contains a smart contract implementation for **Token Vesting**, designed to securely distribute tokens over a predefined vesting schedule. The contract ensures that tokens are gradually released over time to the specified beneficiaries, following customizable rules and timeframes. It is particularly useful for projects that wish to manage token allocations to team members, investors, advisors, or other stakeholders in a transparent and automated manner.

## Features
- Secure and automated token distribution
- Customizable vesting schedules
- Support for immediate cliff vesting
- Token withdrawal and vesting cancellation functionalities

## Methods

### 1. `create_vesting<T>`
To create a vesting for coin type `T`.

**Parameters:**
- `_coin`: Object ID of balance for coin type `T`.
- `_clock`: Object ID of clock (`0x0000000000000000000000000000000000000000000000000000000000000006`).
- `_amount`: Amount to be vested for a particular beneficiary (excluding cliff amount).
- `_totalPeriods`: Total number of intervals in which the full amount will be vested.
- `_amountPerPeriod`: Number of tokens to be released per interval.
- `_cliffAmount`: Amount vested immediately once the vesting object is created.
- `_end`: Epoch timestamp for the end of the vesting schedule.
- `_sender`: Address of the vesting manager.
- `_recipient`: Address of the vesting beneficiary.
- `_start`: Epoch timestamp for the start of the vesting schedule.
- `_releaseSchedule`: Type of release schedule: 
  - `0`: Daily
  - `1`: Weekly
  - `2`: Monthly

### 2. `withdraw<T>`
To withdraw tokens of type `T`.

**Parameters:**
- `_clock`: Object ID of the clock (`0x0000000000000000000000000000000000000000000000000000000000000006`).
- `vesting_id`: Object ID of the vesting object generated during the `createVesting` method invocation.

### 3. `cancel<T>`
To cancel the vesting for coin type `T` (remaining tokens will be sent back to the sender's address).

**Parameters:**
- `_clock`: Object ID of the clock (`0x0000000000000000000000000000000000000000000000000000000000000006`).
- `vesting_id`: Object ID of the vesting object generated during the `createVesting` method invocation.

## Deployment and Execution Instructions

To deploy and execute the smart contract, follow the steps below:

1. **Install the Sui framework**:
   ```bash
   brew install sui
   ```
2. **Create a new Sui address**:
    ```bash
    sui client new-address <address-scheme>
    ```
3. **Request gas**:
    ```bash
    curl --location --request POST 'https://<network>/v1/gas' \--header 'Content-Type: application/json' \--data-raw '{
    "FixedAmountRequest": {"recipient": "<YOUR SUI ADDRESS>"}}'
    ```
4. **Build the smart contract**:
    ```bash
    sui move build
    ```
5. **Check gas balance**:
    ```bash
    sui client gas
    ```
6. **Publish the smart contract**:
    ```bash
    sui client publish --gas-budget <gas-budget> --skip-dependency-verification
    ```

## License
// Copyright (c) Elysyal.  
// SPDX-License-Identifier: Apache-2.0