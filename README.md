# Lotus Router

A free and open source, dynamic, extensible router smart contract.

Built with experience from the frontier, with solidarity for developers of
sovereignity, and with a love for democratization of knowledge and software.

> Work In Progress, Do Not Use Yet

## Why?

Searchers and Solvers alike employ people like us to repeatedly build the state
of the art in router technolopy.

Searchers and Solvers alike justify secrecy with "alpha decay" and other pseudo-
academic terminology in order to hoarde the cutting edge and the capital which
comes with it.

<br/>

We grow tired of building the same software again and again.

We grow tired of signing NDA after NDA.

We grow tired of repeating ourselves.

<br/>

So we the Researchers and Developers write this software with the intent to
democratize the cutting edge of router technology.

So we the Researchers and Developers write this software with the intent to
liberate the secrets of a parasitic industry.

So we the Researchers and Developers write this software with the intent to
expose the elegant simplicity which hides behind bytecode obfuscators and the
mysticism of our local elites.

## Disclaimer

Multiple organizations may contend that this technology was stolen, or that it
is the subject of trade secrets.

However, we the Researchers and Developers formally declare this software is
developed explicitly on our own time, on our own hardware, with our own
software, and with our own knowledge accumulated from both educational resources
and through our understanding and interpretation of the bytecode which exists on
the public blockchains.

## Implementation Details

Batchable actions:

- [ ] Uniswap V2 Swap Exact In
- [ ] Uniswap V2 Swap Exact Out
- [ ] Uniswap V3 Swap Exact In
- [ ] Uniswap V3 Swap Exact Out
- [ ] Uniswap V4 Swap Exact In
- [ ] Uniswap V4 Swap Exact Out
- [ ] ERC20 Transfer
- [ ] ERC20 TransferFrom
- [ ] ERC721 TransferFrom
- [ ] ERC6909 Transfer
- [ ] ERC6909 TransferFrom
- [ ] Wrap WETH
- [ ] Unwrap WETH

## Open Design Questions

Should we treat the pointer `Ptr` as the central component in the router?
Or should we treat all unpacked addresses as the central components?

That is to say, we can continuously increment the pointer on each action,
comparable to the pseudocode as follows:

```
let ptr

let (ptr, action) = ptr.loadAction();

if action == Action.UniV2Swap {
    let (ptr, success) = ptr.callUniV2Swap();
}

// -- snip
```

Or should it be independent of the pointer, comparable to the pseudocode as
follows:

```
let ptr

let (ptr, action) = ptr.loadAction();

if action == Action.UniV2Swap {
    let (ptr, pair) = ptr.loadWord();
    let (ptr, amount0Out) = ptr.loadWord();
    let (ptr, amount1Out) = ptr.loadWord();
    let (ptr, to) = ptr.loadWord();
    let (ptr, dataPtr) = ptr.loadWord();

    let success = pair.swap(amout0Out, amoutn1Out, to, dataPtr);
}

// -- snip
```
