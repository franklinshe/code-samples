# code-samples
Some snippets of code from various projects I've worked on that I'm particularly proud of!

## `sysfile.c`  mCertikos Operating System

In my Operating Systems class, I built out a micro certified OS kernel in C running on the QEMU open-source simulator. I implemented components of physical and virtual memory, process and thread management, trap and interrupt handling, scheduling and concurrency, and a file system. For our final project, my partner and I added support for file sharing synchronization through an implementation of BSD file locks ([flock](https://man7.org/linux/man-pages/man2/flock.2.html)). This defined and solved the mutual exclusion issue when multiple user threads open one file. Here's a [code sample](https://github.com/franklinshe/code-samples/blob/master/sysfile.c#L582) of part of the implementation and a usage example:

```{c}
/* acquire shared lock in non-blocking mode */
if (flock(fd, LOCK_SH | LOCK_NB) == -1) {
    exit(1);
}
/* non-atomically upgrade to exclusive lock */
if (flock(fd, LOCK_EX) == -1) {
    exit(1);
}
/* release lock */
if (flock(fd, LOCK_UN) == -1) {
    exit(1);
```

## `exchange.sol` Decentralized CFMM Exchange

After taking a course on Blockchain and Cryptocurrency, I learned about permissionless and secure market protocols and implemented a constant function market maker (CFMM) modeled after the Uniswap V1 Protocol. I also created an ERC-20 token and a web client allowing users to swap tokens or provide or remove liquidity. Here's a [code sample](https://github.com/franklinshe/code-samples/blob/master/exchange.sol) of the smart contract for the exchange and an intuitive diagram of a sandwich attack, a form of front-running, that this implementation attempts to curb through limits on slippage.

![image](https://github.com/franklinshe/code-samples/assets/65642896/9a4f9f89-6641-4706-9d12-167378259c33)

### Other Projects

- [Command-line TeX-like compiler](https://github.com/franklinshe/tex-macro-processor) in C
- [Ethereum blockchain backend buy/sell marketplace](https://github.com/franklinshe/marketplace-dapp) in React and Solidity

