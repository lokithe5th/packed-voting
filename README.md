# Flipping Bits for Fun (and Profit)  

This build focuses demonstrating bit packing and manipulation through a simple proposal and voting dApp.  

The focus should be on the packages/hardhat/contracts folder, which contains the `Voting.sol` and `IVoting.sol` files. 

Simple tests are provided in the packages/hardhat/tests as an example. 

**NB: Do not use in production without modification**

## Introduction  
If you're like me, you've probably come across some beautiful smart contracts that innovate and show you different sides of Solidity. Recently I came across [this beauty from Chiru Labs](https://github.com/chiru-labs/ERC721A) while working on my [tax-loss harvest0r build](https://github.com/lokithe5th/harvest0r) for the BuidlGuidl. 

I loved the bit manipulations and of course, the cherry on top, that this might result in some good gas optimizations while reducing the storage footprint of contracts - meaning greater profits for users and protocols 😃 The only problem? I hadn't worked with bit manipulations yet. The solution: build something with it!  

## Bits and Pieces  
This led me down the rabbithole of bits, bytes, hexadecimals and uint types. As I evolve the optimizations over time I'm sure I will discover significant bytecode optimizations - but that's the next build.

So in condensed form, here are the things you need to know to get started:  

1. `1 byte` in binary is 8 bits (`byte == 8 bits`), i.e. `0001 1111`
2. `1 byte` in hexadecimal is 2 character long, i.e. `1f`
3. `0x` is prefixed to bytes values in Solidity, but only the characters after `0x` are used, i.e., `0x1f = 8 bits = 0001 1111 = 32 decimal` 
4. `uint256` means `256 bits` to represent an unsigned integer. 
5. Thus `type(uint256).max` will equal `2**256 - 1` in decimal (`-1` because we start at `0`) or a 32 character hexadecimal value `0xffffffffffffffffffffffffffffffff`, or 256 character binary value, `1111...1111`.
6. Stepping down towards `type(uint64).max` we get: `2**64 - 1` = `0xffffffff` = 64 character binary value `1111....1111`; and so forth.
7. In case you haven't noticed, packing means we want to manipulate bits at specific positions.

## Bit manipulations  
How do we manipulate bits in Solidity? We use the bitwise operators `>>`, `<<`, `&` and `|`, for shift right, shift left, bitwise `and`, bitwise `or`, respectively.  

Bear in mind, there are more, but these are enough to get you started. 

### `>>`  
The bitwise right shift is used like this `a >> b`, where `a` is the value to be shifted and `b` is the number of bits to shift `a` with towards the left.  

For example, let's take a `uint8` value assigned to `uint256 private x`, at it's maximum value (we can get this with `type(uint8).max`) which is `255` in decimal.

We can represent `x` as `1111 1111` in binary.

`(x >> 4)` means we want to shift the value `x` towards the right by 4 bits. For every character we shift to the right, we lose the rightmost character, and we add a `0` to the left. 

Thus, `0000 1111`

### `<<`  
The bitwise left shift is used like this `a << b`, where `a` is the value to be shifted and `b` is the number of bits to shift `a` with `b` towards the right. 

Again, for a variable `x` with a decimal value `255`:
`(x << 4)` we get `1111 1111 0000`, or `4080`. 

As you can see, we have now gained four `0`'s to the right of the value. 

But it is in this spot that the first **gotcha** can be found.

*The type matters for values being shifted to the right.*

Because `x` is a `uint256` the leftmost values aren't lost. Unless you shift `x` more values to the left than are available, at which point they will be cut off. 

So what if we wanted to only have a `uint8` as our maximum? We should then cast the result to `uint8(x)`. This will cut off all values to the left of the last 8 bits of `x`, giving a different result: `1111 0000`. 

Be very careful when shifting values. It will help to make a map of your bit layouts when packing and manipulating data (these can be represented as hexadecimal values too).

### `&`  
The bitwise `and` is simple. It takes two values, `a & b` and compares their bits.
If `a`: `0001 1000` and `b: 0000 0001`
    `0001 1010`
    `0010 0011`
=   `0000 0010`

It simply compares each bit and if both bits are `1` it returns a `1` for that bit position. Else it returns a `0`. 

Where is this useful? Let's say you stored a value in the last 4 bits of `b`. If you want to clear the last four bits of `b`, you can do `b & 1111`, which will return `0` for all bits except the last four. This can be used to mask values you don't need at the moment.

### `|`  
The bitwise `or` is used to mix two packed values together. It takes `a | b` and compares their bits. If `a`: `1010 0000` and `b: 0000 1010`; we are storing a value in the first four bits of `a` and another value in the last 4 bits of `b`. To pack these into one 8 bit variable we do `a | b` and get:
    `1010 0000`
    `0000 1010`
=   `1010 1010`

It compares each bit position and if the value is a `0` or `1` it returns `1`, if both are `0` it returns `0`.

This is useful when you want to combine values to pack them into one record.

## Packing Up Bits  
To put these concepts together let's say the BuidlGuidl members have all written two Solidity quizzes to once and for all determine who are the `⚔ Knights of the Buidl Guidl ⚔` 

The quizzes have maximum values of 15 points each. The test is on chain, so we need to store the scores by address.

Being clever you decide to pack the results of the two quizzes into a `uint8` value stored in the `mapping(address => uint8) private testScores`. This saves you from declaring two storage variables or doing a nested mapping to store everything.

So let's break it down. 
1. Each test has a max value of 15, or `1111` in binary.
2. We want to store `test1` in the rightmost 4 bits `[4 bits][test1]`
3. We want to store `test2` in the leftmost 4 bits `[test2][4 bits]`

To pack `test1` and `test2` together, we can do:
1. `packedScore = (test2 << 4)` : this shifts `test2` 4 bits to the left, leaving `0000` as the last 4 bits in `packedScore`  
2. `packedScore = packedScore & test1` : this performs an `or` operation, packing the result into `packedScore`.
3. `testScores[user] = packedScore`

Bonus round: how would you do the above in less lines?

## Wrapping up  

Now that you have a better idea about bit manipulations and operators in Solidity, take a look at the `contracts` folder which contains the `Voting.sol` file where I tried this out for myself.  

Always be very careful when using bitwise manipulations. Test thoroughly and remember to take into account that bits aren't always as clean as you might expect them to be.

Remember, be careful:
If `x` = `shift`, `b` = `00001` 
One digit shifted too far can get you in = `(x & b) | ((x >> 2) << 1)`


Did you catch a mistake? Hmu on the BuidlGuidl telegram group 🛡

Comments, suggestions and corrections welcome.

# 🏗 Scaffold-ETH

> everything you need to build on Ethereum! 🚀

🧪 Quickly experiment with Solidity using a frontend that adapts to your smart contract:

![image](https://user-images.githubusercontent.com/2653167/124158108-c14ca380-da56-11eb-967e-69cde37ca8eb.png)


# 🏄‍♂️ Quick Start

Prerequisites: [Node (v16 LTS)](https://nodejs.org/en/download/) plus [Yarn (v1.x)](https://classic.yarnpkg.com/en/docs/install/) and [Git](https://git-scm.com/downloads)

> clone/fork 🏗 scaffold-eth:

```bash
git clone https://github.com/scaffold-eth/scaffold-eth.git
```

> install and start your 👷‍ Hardhat chain:

```bash
cd scaffold-eth
yarn install
yarn chain
```

> in a second terminal window, start your 📱 frontend:

```bash
cd scaffold-eth
yarn start
```

> in a third terminal window, 🛰 deploy your contract:

```bash
cd scaffold-eth
yarn deploy
```

🔏 Edit your smart contract `YourContract.sol` in `packages/hardhat/contracts`

📝 Edit your frontend `App.jsx` in `packages/react-app/src`

💼 Edit your deployment scripts in `packages/hardhat/deploy`

📱 Open http://localhost:3000 to see the app

# 📚 Documentation

Documentation, tutorials, challenges, and many more resources, visit: [docs.scaffoldeth.io](https://docs.scaffoldeth.io)


# 🍦 Other Flavors
- [scaffold-eth-typescript](https://github.com/scaffold-eth/scaffold-eth-typescript)
- [scaffold-eth-tailwind](https://github.com/stevenpslade/scaffold-eth-tailwind)
- [scaffold-nextjs](https://github.com/scaffold-eth/scaffold-eth/tree/scaffold-nextjs)
- [scaffold-chakra](https://github.com/scaffold-eth/scaffold-eth/tree/chakra-ui)
- [eth-hooks](https://github.com/scaffold-eth/eth-hooks)
- [eth-components](https://github.com/scaffold-eth/eth-components)
- [scaffold-eth-expo](https://github.com/scaffold-eth/scaffold-eth-expo)
- [scaffold-eth-truffle](https://github.com/trufflesuite/scaffold-eth)



# 🔭 Learning Solidity

📕 Read the docs: https://docs.soliditylang.org

📚 Go through each topic from [solidity by example](https://solidity-by-example.org) editing `YourContract.sol` in **🏗 scaffold-eth**

- [Primitive Data Types](https://solidity-by-example.org/primitives/)
- [Mappings](https://solidity-by-example.org/mapping/)
- [Structs](https://solidity-by-example.org/structs/)
- [Modifiers](https://solidity-by-example.org/function-modifier/)
- [Events](https://solidity-by-example.org/events/)
- [Inheritance](https://solidity-by-example.org/inheritance/)
- [Payable](https://solidity-by-example.org/payable/)
- [Fallback](https://solidity-by-example.org/fallback/)

📧 Learn the [Solidity globals and units](https://docs.soliditylang.org/en/latest/units-and-global-variables.html)

# 🛠 Buidl

Check out all the [active branches](https://github.com/scaffold-eth/scaffold-eth/branches/active), [open issues](https://github.com/scaffold-eth/scaffold-eth/issues), and join/fund the 🏰 [BuidlGuidl](https://BuidlGuidl.com)!

  
 - 🚤  [Follow the full Ethereum Speed Run](https://medium.com/@austin_48503/%EF%B8%8Fethereum-dev-speed-run-bd72bcba6a4c)


 - 🎟  [Create your first NFT](https://github.com/scaffold-eth/scaffold-eth/tree/simple-nft-example)
 - 🥩  [Build a staking smart contract](https://github.com/scaffold-eth/scaffold-eth/tree/challenge-1-decentralized-staking)
 - 🏵  [Deploy a token and vendor](https://github.com/scaffold-eth/scaffold-eth/tree/challenge-2-token-vendor)
 - 🎫  [Extend the NFT example to make a "buyer mints" marketplace](https://github.com/scaffold-eth/scaffold-eth/tree/buyer-mints-nft)
 - 🎲  [Learn about commit/reveal](https://github.com/scaffold-eth/scaffold-eth-examples/tree/commit-reveal-with-frontend)
 - ✍️  [Learn how ecrecover works](https://github.com/scaffold-eth/scaffold-eth-examples/tree/signature-recover)
 - 👩‍👩‍👧‍👧  [Build a multi-sig that uses off-chain signatures](https://github.com/scaffold-eth/scaffold-eth/tree/meta-multi-sig)
 - ⏳  [Extend the multi-sig to stream ETH](https://github.com/scaffold-eth/scaffold-eth/tree/streaming-meta-multi-sig)
 - ⚖️  [Learn how a simple DEX works](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90)
 - 🦍  [Ape into learning!](https://github.com/scaffold-eth/scaffold-eth/tree/aave-ape)

# 💌 P.S.

🌍 You need an RPC key for testnets and production deployments, create an [Alchemy](https://www.alchemy.com/) account and replace the value of `ALCHEMY_KEY = xxx` in `packages/react-app/src/constants.js` with your new key.

📣 Make sure you update the `InfuraID` before you go to production. Huge thanks to [Infura](https://infura.io/) for our special account that fields 7m req/day!

# 🏃💨 Speedrun Ethereum
Register as a builder [here](https://speedrunethereum.com) and start on some of the challenges and build a portfolio.

# 💬 Support Chat

Join the telegram [support chat 💬](https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA) to ask questions and find others building with 🏗 scaffold-eth!

---

🙏 Please check out our [Gitcoin grant](https://gitcoin.co/grants/2851/scaffold-eth) too!

### Automated with Gitpod

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#github.com/scaffold-eth/scaffold-eth)
