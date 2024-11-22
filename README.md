# Story
[Story](https://x.com/StoryProtocol) is building the world's first IP network, making intellectual property programmable on the blockchain for creators and builders. Further information can be found on Story Foundation's [website](https://www.story.foundation/).

## Installation
[Story's architecture](https://docs.story.foundation/docs/odyssey-node-setup) uses separate execution and consensus clients for better scalability. To run a validator node, you need two components: the `story-geth` execution client and the `story` consensus client.

### prerequisites
- CPU: **4 Cores**
- Memory: **16 GB RAM**
- Disk: **500 GB SSD**
- Machine: **Ubuntu 22.04+**

### script execution
To quickly set up your node, run this script:
```
wget -O story.sh https://api.denodes.xyz/story.sh && bash story.sh
```
After installation, wait for full synchronization. The command below should return `false`:
```
curl -s localhost:26657/status | jq .result.sync_info.catching_up
```
### wallet & faucet

Next, proceed to export your validator key
```
story validator export
```
```
Compressed Public Key (hex): 03bdc7b8940babe9226d52d7fa299a1faf3d64a82f809889256c8f146958a63984
Compressed Public Key (base64): A73HuJQLq+kibVLX+imaH689ZKgvgJiJJWyPFGlYpjmE
Uncompressed Public Key (hex): 04bdc7b8940babe9226d52d7fa299a1faf3d64a82f809889256c8f146958a6398496b9e2af0a3a1d199c3cc1d09ee899336a530c185df6b46a9735b25e79a493af
EVM Address: 0x9EacBe2C3B1eb0a9FC14106d97bd3A1F89efdDCc
Validator Address: storyvaloper1p470h0jtph4n5hztallp8vznq8ehylsw9vpddx
Delegator Address: story1p470h0jtph4n5hztallp8vznq8ehylswtr4vxd
```
You can export the derived EVM private key of your validator into the default data config directory:
```
story validator export --export-evm-key
```
Request test tokens from the [Faucet](https://faucet.story.foundation/) and topup your validator wallet.
Check your balance [Storyscan](https://odyssey-testnet-explorer.storyscan.xyz/)

### validator creation

```
source $HOME/.bash_profile
story validator create --stake 1000000000000000000 --moniker $MONIKER
```
