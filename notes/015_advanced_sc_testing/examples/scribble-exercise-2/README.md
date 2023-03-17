# Scribble Exercise 2

In this exercise we're going to have a look at a vulnerable ERC721 smart
contract. The contract in question ([contracts/VulnerableERC721.sol](https://github.com/ConsenSys/scribble-exercise-2/blob/master/contracts/VulnerableERC721.sol)) is
copied almost verbatim from
https://github.com/OpenZeppelin/openzeppelin-contracts, except that:

  1) the imports have been adjusted a little
  2) a bug has been inserted somnewhere
  3) and the `_mint` function has been made public to give the MythX engine more room to play.

We'll use Scribble to annotate it with properties, and use the MythX service (and more specifically the fuzzing engine behind it) to automatically check the properties (and find the bug 🐛).

### Handy Links
Scribble Repository -> https://github.com/ConsenSys/Scribble

Mythril Repository -> https://github.com/ConsenSys/Mythril

Scribble Docs 📚 -> https://docs.scribble.codes/

MythX Dashboard -> https://dashboard.mythx.io

### Installation
```
# We'll need the mythx-cli client:
pip3 install mythx-cli

# Make sure to use node 12-14
npm install eth-scribble --global
```

Also you will need a **developer MythX account** and the associated API key.

### Setting up the target

```
git clone git@github.com:ConsenSys/scribble-exercise-2.git
cd scribble-exercise-2
```


### Finding the vulnerability
The vulnerability can be triggered from the [`transferFrom()`](https://github.com/ConsenSys/scribble-exercise-2/blob/master/contracts/VulnerableERC721.sol#L228) function.

To find it we will add some specs to `transferFrom()`. A good source of specs is the docstring above [`IERC721.transferFrom`](https://github.com/ConsenSys/scribble-exercise-2/blob/master/contracts/IERC721.sol#L40):
```
    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
```
This docstring includes some informal specification of how `transferFrom()` should behave. We will turn these into formal Scribble annotations.

### Adding annotations

We can extract the following specs from the above docstring:
<details>
<summary> If the transfer succeeds, then `from` is not 0.</summary>
<br>
<pre>
    /// #if_succeeds {:msg "From is never 0"}  from != address(0);
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        ...
    }
</pre>
</details>

<details>
<summary> If the transfer succeeds then `to` is not 0. (i.e. you can't destroy NFTs).</summary>
<br>
<pre>
    /// #if_succeeds {:msg "Can't destroy NFTs."}  to != address(0);
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        ...
    }
</pre>
</details>

<details>
<summary> If the transfer succeeds then `tokenId` must be owned by `from`.</summary>
<br>
<pre>
    /// #if_succeeds {:msg "Correct from."}  from == old(ownerOf(tokenId));
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        ...
    }
</pre>

Note the use of `old()` here to talk about the owner of `tokenId` **before** the transfer was executed.
</details>

<details>
<summary> If the transfer succeeds then the caller must be authorized to perform the transfer. I.e. either 1) the caller is `from` or 2) the caller is approved for this token or 3) the caller is an authorized operator for `from`.</summary>
<br>
<pre>
    /// #if_succeeds {:msg "Authorized user."}  let oldOwner := old(ownerOf(tokenId)) in msg.sender == oldOwner || getApproved(tokenId) == msg.sender || isApprovedForAll(oldOwner, msg.sender);
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        ...
    }
</pre>

</details>

### Finding the bug using fuzzing (with MythX)

To find the bug, make sure first you have added your MythX API key to your environment:

```
export MYTHX_API_KEY=<your key>
```

And then you can run:
```
mythx \
    --format simple \
    analyze --mode standard contracts/VulnerableERC721.sol \
    --check-properties \
    --scribble \
    --solc-version 0.6.2 
```

There's quite a bit going on in this command so lets quickly unpack it:

 * `--format simple` just specifies the output format for the issues found
 * `analyze contracts/VulnerableERC721.sol` is the actual sub-command. It instructs `mythx-cli` to send an analysis request for the specified file.
 * `--check-properties` instructs MythX to focus just on violations to user specs, and not waste time on other kind of issues (e.g. integer overflows)
 * `--scribble` tells `mythx-cli` to automatically run `scribble` on the target contracts to instrument them, before submitting to the API
 * `--solc-version 0.6.2` - mythx-cli will complain if you dont' explicitly give it the Solidity version

After a short while, you should see some issues prop up. Which property was violated?

Now knowing which property was violated, can you see where in the code the bug was introduced :)?

### Finding the bug more manually

The above `mythx` command we ran does sereral things under the hood:

1) Instrument the target file (and potentially any dependencies)

2) Flatten the instrumented target file (and all its dependencies) into a single Solidity file

3) Submit the flat solidity file to the API for analysis.

4) Map the resulting failures in the **flattened** Solidity file into violated annotations in the **original** file.

Sometimes it may be useful to do instrumentation and analysis separately. (for example when debugging, or in case you want to see the instrumented file. You can do this with the following 2 commands:

```
# Instrument the files in-place
scribble --arm -m files contracts/VulnerableERC721.sol --compiler-version 0.6.2
# Submit the instrumented target contract for analysis
mythx --format simple analyze contracts/VulnerableERC721.sol --check-properties --solc-version 0.6.2
```

After you run the first command you can inspec `contracts/VulnerableERC721.sol` to see what the instrumented code looks like.
