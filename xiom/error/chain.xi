// XIOM - Error: Error Chaining
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.error.chain

// Depends on: xiom.error

// ============================================================================
// Linked error chains with push/pop, message listing, root/top access and
// iteration. NOTE: current implementation lives in error.xi - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Error - an error node holding a message and an optional cause (the next node in the chain).
// fn error_chain_new(message: Str) -> Error - create a chain with a single message. TODO(compiler): implement.
// fn error_chain_push(e: Error, message: Str) -> Error - add a message onto the chain and return the new head. TODO(compiler): implement.
// fn error_chain_pop(e) -> Option[Error] - remove and return the head, exposing the previous cause. TODO(compiler): implement.
// fn error_chain_len(e) -> Int - the number of messages in the chain. TODO(compiler): implement.
// fn error_chain_messages(e) -> Vec[Str] - all messages from head to root. TODO(compiler): implement.
// fn error_chain_root(e) -> Str - the oldest (root) message. TODO(compiler): implement.
// fn error_chain_top(e) -> Str - the newest (head) message. TODO(compiler): implement.
// fn error_chain_iter(e) -> Vec[Error] - all nodes from head to root. TODO(compiler): implement.
// fn error_chain_has(e, message) -> Bool - whether any node carries the message. TODO(compiler): implement.
