// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2024 dxo
pragma solidity ^0.8.27;

contract Multi {

  // -- DATA ---------------------------------------------------------------------------------------

  // address => signer status
  mapping (address => bool) public signers;
  // total number of signers
  uint public size;

  // proposal hash => confirmation count
  mapping (bytes32 => uint) public confirmations;
  // proposal hash => approver => confrmation
  mapping (bytes32 => mapping (address => bool)) public confirmed;
  // proposal hash => executed
  mapping (bytes32 => bool) public executed;

  // approval threshold
  uint public min;

  // proposal executor
  Proxy immutable public proxy;

  // -- LOGS ---------------------------------------------------------------------------------------

  event Rely(address usr);
  event Deny(address usr);
  event Min(uint val);

  event Confirm(address signer, address usr, bytes data, uint chain, uint nonce);
  event Exec(address usr, bytes data, uint chain, uint nonce);

  // -- SETUP --------------------------------------------------------------------------------------

  constructor() {
    proxy = new Proxy();

    min = 1;
    emit Min(1);

    signers[msg.sender] = true;
    emit Rely(msg.sender);
  }

  // --- PROPOSAL LIFECYCLE ------------------------------------------------------------------------

  function confirm(address usr, bytes calldata data, uint chain, uint nonce) external {
    bytes32 id = hash(usr, data, chain, nonce);

    require(signers[msg.sender], "unauthorized");
    require(!executed[id], "already executed");
    require(!confirmed[id][msg.sender], "already confirmed");

    confirmations[id] += 1;
    confirmed[id][msg.sender] = true;

    emit Confirm(msg.sender, usr, data, chain, nonce);
  }

  function exec(address usr, bytes calldata data, uint chain, uint nonce) external {
    bytes32 id = hash(usr, data, chain, nonce);

    // checks
    require(block.chainid == chain, "chainid mismatch");
    require(!executed[id], "already executed");
    require(confirmations[id] >= min, "insufficient confirmations");
    require(msg.sender != address(proxy), "recursive exec encountered");

    // effects
    executed[id] = true;

    // interactions
    proxy.exec(usr, data);

    // logs
    emit Exec(usr, data, chain, nonce);
  }

  // --- ADMIN ------------------------------------------------------------------------------------

  function rely(address usr) public {
    require(msg.sender == address(proxy), "unauthorized");
    require(!signers[usr], "usr must not already be a signer");

    signers[usr] = true;
    size += 1;

    emit Rely(usr);
  }

  function deny(address usr) public {
    require(msg.sender == address(proxy), "unauthorized");
    require(size > 0, "cannot remove last signer");
    require(min < size, "cannot reduce size below min");
    require(signers[usr], "usr must already be a signer");

    signers[usr] = false;
    size -= 1;

    emit Deny(usr);
  }

  function move(uint val) public {
    require(msg.sender == address(proxy), "unauthorized");
    require(val <= size, "min cannot be larger than size");
    require(val > 0, "at least one confirmation must be required");

    min = val;

    emit Min(val);
  }

  // --- UTIL -------------------------------------------------------------------------------------

  function hash(address usr, bytes memory data, uint chain, uint nonce) public pure returns (bytes32) {
    return keccak256(abi.encode(usr, data, chain, nonce));
  }
}

contract Proxy {
  address immutable public owner;

  constructor() {
    owner = msg.sender;
  }

  function exec(address usr, bytes calldata data) external {
    require(msg.sender == owner, "unauthorized");
    (bool ok,) = usr.delegatecall(data);
    require(ok, "proposal execution failed");
  }
}
