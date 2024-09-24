pragma solidity ^0.8.27;

contract Multi {

  // -- DATA ---------------------------------------------------------------------------------------

  // address => owner status
  mapping (address => bool) public owners;
  // proposal hash => confirmations
  mapping (bytes32 => uint) public confirmations;
  // proposal hash => approver => approved
  mapping (bytes32 => mapping (address => bool)) public confirmed;
  // proposal hash => proposed
  mapping (bytes32 => bool) public proposed;
  // approval threshold
  uint min;
  // unique per proposal id
  uint next;

  struct Proposal {
    bool proposed;
    bool executed;
    uint confirmations;
    mapping (address => bool) approved;
  }

  // -- SETUP --------------------------------------------------------------------------------------

  constructor() {
    owners[msg.sender] = true;
    min = 1;
  }

  // --- PROPOSAL EXECUTION ------------------------------------------------------------------------

  function propose(address usr, bytes32 tag, bytes calldata data) external {
    require(owners[msg.sender], "unauthorized");
    proposed[hash(usr, tag, data, next)] = true;
    next += 1;
  }

  function confirm(address usr, bytes32 tag, bytes calldata data, uint nonce) external {
    bytes32 id = hash(usr, tag, data, nonce);

    require(owners[msg.sender], "unauthorized");
    require(proposed[id], "not proposed");
    require(!confirmed[id][msg.sender], "already confirmed");

    confirmations[id] += 1;
    confirmed[id][msg.sender] = true;
  }

  function exec(address usr, bytes32 tag, bytes calldata data, uint nonce) external {
    bytes32 id = hash(usr, tag, data, nonce);

    // checks
    require(proposed[id], "not proposed");
    require(confirmations[id] > min, "insufficient confirmations");
    require(soul(usr) == tag, "codehash does not match tag");

    // interactions
    (bool ok,) = usr.delegatecall(data);
    require(ok, "proposal execution failed");
  }


  function hash(address usr, bytes32 tag, bytes memory data, uint nonce) public pure returns (bytes32) {
    return keccak256(abi.encode(usr, tag, data, nonce));
  }

  function soul(address usr) internal view returns (bytes32 tag) {
    assembly { tag := extcodehash(usr) }
  }
}
