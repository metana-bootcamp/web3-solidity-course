# Scribble Exercise Uniswap

The constant product AMM is a simple, yet very common and well known pattern in DeFi. This exercise will explore Uniswaps V2 implementation of a constant product AMM. We'll look at several aspects and how we can formalise specifications of the uniswap contracts as annotations. 

### Handy Links
Scribble Repository -> https://github.com/ConsenSys/Scribble
Scribble Docs 📚 -> https://docs.scribble.codes/

### Installation
```
npm install eth-scribble --global
```

### Setting up the target

```
git clone https://github.com/ConsenSys/scribble-exercise-uniswap.git
```


### Approach
We should review a general strategy before diving in head-first trying to write properties. The following steps are three that we commonly use when approaching a new system that has to be annotated.

1. What is the central functionality of the system? 
2. What are the core assumptions that other people will have when integrating with your code?
3. What aspect of the code has the most risk / holds the most funds?

Functionality:
* Allow liquidity providers to take a position to enable swaps and earn yield.
* Allow traders to trade between assets.
Core Assumption:
* The market has a constant product that doesn't change between trades
Aspect of the code with the most risk:
* UniswapV2Pair.sol has all the tokens and swap logic


### Adding annotations
First we have the core property of a constant product AMM, the *constant product invariant*:
<details>
<summary>The product of the reserves can only grow with every trade</summary>
<br>
<pre>
/// #if_succeeds old(reserve0 * reserve1) >= reserve0 * reserve1;
function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
</pre>
</details>


The constant product doesn't always have to grow! Mints and burns are allowed to change it, they do have to preserve the price though:
<details>
<summary> Burning tokens preserves the price of the uniswap pair</summary>
<br>
<pre>
/// #if_succeeds old(reserve0) / old(reserve1) == reserve0 / reserve1;
function burn(address to) external lock returns (uint amount0, uint amount1) {
</pre>
</details>


Burning is a bit simpler than minting. If you mint liquidity tokens then uniswap doesn't mind you changing the price, it just won't give you liquidity tokens for the overage.
<details>
<summary> Minting liquidity should give me tokens relative to the smallest ratio of reserve increases</summary>
<br>
<pre>
/// #if_succeeds 
/// let ratio0 := reserve0 / IERC20(token0).balanceOf(address(this)) in
/// let ratio1 := reserve1 / IERC20(token1).balanceOf(address(this)) in
/// totalSupply != 0 ==> liquidity <= ratio0 * old(totalSupply) && liquidity <= ratio0 * old(totalSupply);
function mint(address to) external lock returns (uint liquidity) {
</pre>
</details>


These were some of the core behaviours! Go and see if you can find some more to annotate yourself! Here is another simple one to finish off this workshop:

<details>
<summary> After calling sync the balance of the pair should be in sync with the reserves. </summary>
<br>
<pre>
/// #if_succeeds IERC20(token0).balanceOf(address(this)) == reserve0;
/// #if_succeeds IERC20(token1).balanceOf(address(this)) == reserve1;
function sync() external lock {
</pre>
</details>

### Instrumenting

Instrumentation is almost trivial now that you've written these properties! Run the following command:

```
scribble -m files --arm ./src UniswapV2PairAnnotated
```
