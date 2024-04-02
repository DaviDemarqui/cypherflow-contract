## Cypherflow V1

**Cypherflow is an web3 Stack Overflow alternative where developers help each other and earn money by doing it :)**

Cypherflow V1 consists of:

-   **CypherCore**: Core contract that handle the main functionality of the platform like questions, answers, payments and more.
-   **CypherGov**: The DAO Governance contract where proposals, votes are handled.
-   **Cypher Token**: Comming soon...

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
