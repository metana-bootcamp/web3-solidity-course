* You deploy contract "Personal Bank" and deposit funds, either in the constructor or at any time by sending to the contract. When you want to transfer some funds to another person, you write a cheque. This is a signed message that can be used to claim the funds ("cash the cheque"). The message is then sent to the recipient off-chain. So, writing a cheque costs you no gas fees. The person who cashes the cheque pays the gas.

* However, there are 2 security problems with this system as written:
 1. **Replay attacks** : A user could cash a cheque multiple times and therefore receive more ETH than intended.
 2. **Cross-contract spends** : If there are multiple banks using the same protocol, then a cheque meant for one bank could be used on any or all of the other banks, which was probably not intended.
* You will have to test this with ganache since remix doesn't provide access to the account private keys, which are needed for signing.
* NOTE: When testing, make sure you have latest version of ganache.