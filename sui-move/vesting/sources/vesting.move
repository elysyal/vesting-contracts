// Copyright (c) Elysyal.
// SPDX-License-Identifier: Apache-2.0
#[allow(implicit_const_copy, unused_const, unused_function, unused_variable)]

module vesting::vesting {

  use sui::clock::Clock;
  use sui::coin::{Self, Coin};
  use sui::balance::{Self, Balance};

  public struct VestingStorage<phantom T> has key {
    id: UID,
    amount: u64,
    totalPeriods: u64,
    completedPeriods: u64,
    amountPerPeriod: u64,
    canceledAt: u64,
    cliffAmount: u64,
    canceled: bool,
    created: u64,
    end: u64,
    lastWithdrawanAt: u64,
    sender: address,
    recipient: address,
    start: u64,
    withdrawn: u64,
    timestamps: vector<u64>,
    balance: Balance<T>,
  } 

  entry public fun create_vesting<T>(
    _coin: &mut Coin<T>,
    _clock: &Clock,
    _amount: u64,
    _totalPeriods: u64,
    _amountPerPeriod: u64,
    _cliffAmount: u64,
    _end: u64,
    _sender: address,
    _recipient: address,
    _start: u64,
    _releaseSchedule: u8,
    ctx: &mut TxContext
  ) {
    let timestamps = get_timestampes(_releaseSchedule, _totalPeriods, _start);
    let vesting_id = object::new(ctx);
    let split_coin = coin::split(_coin, _amount, ctx);
    let vesting = VestingStorage<T> {
      id: vesting_id,
      amount: _amount,
      totalPeriods: _totalPeriods,
      completedPeriods: 0,
      amountPerPeriod: _amountPerPeriod,
      canceledAt: 0,
      cliffAmount: _cliffAmount,
      canceled: false,
      created: _clock.timestamp_ms(),
      end: _end,
      lastWithdrawanAt: 0,
      sender: _sender,
      recipient: _recipient,
      start: _start,
      withdrawn: 0,
      timestamps,
      balance: coin::into_balance(split_coin),
    };

    if (_cliffAmount > 0) {
      let clif_coin = coin::split(_coin, _cliffAmount, ctx);
      transfer::public_transfer(clif_coin, _recipient);
    };

    transfer::share_object(vesting);
  }

  entry public fun withdraw<T>(
    _clock: &Clock,
    vesting_id:  &mut VestingStorage<T>,
    ctx: &mut TxContext,
  ) {
    let (eligible_timestamps, eligible_withdrawal) = get_withdrawal<T>(_clock, vesting_id);
    if (eligible_timestamps > 0) {
      vesting_id.completedPeriods = vesting_id.completedPeriods + eligible_timestamps;
      vesting_id.lastWithdrawanAt = _clock.timestamp_ms();
      vesting_id.withdrawn = eligible_withdrawal;
      let coin = coin::take(&mut vesting_id.balance, eligible_withdrawal, ctx);
      transfer::public_transfer(coin, vesting_id.recipient);
    };
  }

  entry public fun cancel<T>(
    _clock: &Clock,
    vesting_id:  &mut VestingStorage<T>,
    ctx: &mut TxContext,
  ) {
      let available_withdrawal = balance::value(&vesting_id.balance);
      let coin = coin::take(&mut vesting_id.balance, available_withdrawal, ctx);
      vesting_id.canceled = true;
      vesting_id.canceledAt = _clock.timestamp_ms();
      transfer::public_transfer(coin, vesting_id.sender);
  }

  fun get_timestampes(_releaseSchedule: u8, _totalPeriods: u64, _start: u64) : vector<u64> {
    let mut timestamps = vector::empty<u64>();
    if (_releaseSchedule == 0) {
      // Daily Release
      let daily_epoch  = (24 * 60 * 60 * 1000);
      let mut i = 1;
      while (i <= _totalPeriods) {
        let intrval_duration = (i * daily_epoch);
        let release_timestamp = _start + intrval_duration;
        timestamps.push_back(release_timestamp);
        i = i + 1;
      }
    } else if (_releaseSchedule == 1) {
      // Weekly Release
      let daily_epoch  = (24 * 60 * 60 * 1000);
      let weekly_epoch = 7 * daily_epoch;
      let mut i = 1;
      while (i <= _totalPeriods) {
        let intrval_duration = (i * weekly_epoch);
        let release_timestamp = _start + intrval_duration;
        timestamps.push_back(release_timestamp);
        i = i + 1;
      }
    } else if (_releaseSchedule == 2) {
      // Monthly Release
      let daily_epoch  = (24 * 60 * 60 * 1000);
      let monthly_epoch = 30 * daily_epoch;
      let mut i = 1;
      while (i <= _totalPeriods) {
        let intrval_duration = (i * monthly_epoch);
        let release_timestamp = _start + intrval_duration;
        timestamps.push_back(release_timestamp);
        i = i + 1;
      }
    } else {
      // Yearly Release
      let daily_epoch  = (24 * 60 * 60 * 1000);
      let yealy_epoch = 365 * daily_epoch;
      let mut i = 0;
      while (i < _totalPeriods) {
        let intrval_duration = (i * yealy_epoch);
        let release_timestamp = _start + intrval_duration;
        timestamps.push_back(release_timestamp);
        i = i + 1;
      }
    };
    timestamps
  }

  fun get_withdrawal<T>(
    _clock: &Clock,
    _vesting_id: &mut VestingStorage<T>
  ) : (u64, u64) {
    let current_timestamp = _clock.timestamp_ms();
    let release_timestamps = _vesting_id.timestamps;
    let mut i = 0;
    let mut temp_eligible_timestamps = 0;
    let mut eligible_timestamps = 0;
    let mut eligible_withdrawal = 0;
    while (i < release_timestamps.length()) {
      let timestamp = *release_timestamps.borrow(i);
      if (timestamp <= current_timestamp) {
        temp_eligible_timestamps = temp_eligible_timestamps + 1;
      };
      i = i + 1;
    };
    if (temp_eligible_timestamps > 0) {
      eligible_timestamps = temp_eligible_timestamps - _vesting_id.completedPeriods;
      eligible_withdrawal = eligible_timestamps * _vesting_id.amountPerPeriod;
    };
    (eligible_timestamps, eligible_withdrawal)
  }
}

