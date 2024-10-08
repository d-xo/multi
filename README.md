# Multi

**UNTESTED, DEFINITELY BROKEN, DO NOT USE WITH REAL MONEY**

This is a minimal EVM multisig designed for use in low volume, high security cold storage setups.
There is a strong focus on reducing the audit surface area, keeping the number of potential
execution branches small, and using a style that supports mechanized reasoning.

Multi is a single Solidity file. It has no imports or dependencies. It contains no loops, and the
self recursion depth is limited to 1. Most functions has only a single succesful execution path.
There is a single call into unknown code, and dynamically sized `bytes` are used (both unfortunately
unavoidable in the context of a multisig).

## Signers and Thresholds

There is no maximum number of signers. Upon construction the contract is initialized as a 1-of-1
with the deployer being the single signer.

Signers and thresholds can be updated via calls to the following admin methods. These methods can
only be executed as part of an approved proposal:

- `rely(usr)`: adds a new signer
- `deny(usr)`: removes a signer
- `move(val)`: sets the minimum approval threshhold

## Proposals

A proposal describes a single delegatecall operation that can be executed exactly one time iff the
confirmation threshold is passed.

A proposal consists of:

- `address usr`: address to delegatecall into
- `bytes data`: calldata to use
- `uint nonce`: a unique per proposal id

Each proposal has a unique id, defined as `keccack256(abi.encode(usr, data, nonce))`

## Lifecycle

signers can confirm a proposal via a call to `confirm(usr, data, nonce)`.

Once the approval threshold has been met, anyone can execute the proposal via a call to `exec(usr, data, nonce)`.

## Proxy Usage

In order to enforce some of the following invariants, proposals cannot be allowed to make arbitrary
modifications to the storage of the root contract. For this reason the delegatecall execution takes
place in a child contract ensuring that it has an isolated storage context, and state modficiations
can take place only through the methods defined on the root.

When constructing auth schemes that involve Multi you therefore likely want to use the address of
it's `proxy` instead of the root contract itself.

## Invariants

### High Level

- Liveness: It is impossible for the contract to enter a state that would make the creation or execution of future proposals impossible
- Authorization: Each succesful proposal execution must have been confirmed by at least `min` signers beforehand
- Observability: The full internal contract state can be exactly reconstructed using the EVM event log only
- Rogue Signer Resistance: A group of rogue signers numbering less than the min threshhold cannot block their removal by a quorum
- Griefing Resistance: A malicious (non-signer) actor cannot disrupt or interfere with the operation of the multisig

### Administration

- Signers can only be added and removed via proposal execution
- The minimum threshold can only be updated via proposal execution
- The minimum number of approvals can never exceed the total number of signers
- There must always be at least one signer

### Proposal Lifecycle

- A proposal cannot be executed if it does not have at least `min` confirmations
- Each signer can confirm a proposal only once
- Signers cannot confirm already executed proposals
- A proposal cannot be executed more than once
- Proposals that revert are not considered as executed
- Proposals can only be confirmed by signers
- Proposals can be executed by anyone
- Proposals can only be created by signers

### Accounting

- `size` is always equal to the number of active signers
