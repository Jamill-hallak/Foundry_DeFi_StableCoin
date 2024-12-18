
# Foundry DeFi Stablecoin

This repository is a project based on the **Cyfrin Foundry Solidity Course**. It showcases the implementation of a decentralized stablecoin system where users can deposit WETH and WBTC to mint a USD-pegged token.

---

## About

The project demonstrates the creation of a decentralized stablecoin system with functionalities for collateral deposits and token minting. It focuses on core testing strategies, including fuzz and invariant testing, ensuring the robustness of the system. The repository is streamlined and free from third-party tools like Slither and GitLab, focusing purely on Foundry's capabilities.

---

## Getting Started

### Requirements

- **Git**: Ensure `git --version` returns the installed version.
- **Foundry**: Install Foundry, and verify it with `forge --version`.

### Quickstart

1. Clone the repository:
   ```bash
   git clone (https://github.com/Jamill-hallak/Foundry_DeFi_StableCoin.git)
   cd Foundry_DeFi_StableCoin 
   forge build
   ```

2. Deploy and test the contracts with Foundry.

---

## Features

- **Fuzz Testing**: Explore edge cases by providing random, unexpected inputs to the system.
- **Invariant Testing**: Validate the system's integrity by ensuring critical properties always hold true, regardless of input.

---

## Deployment

### Local Node
Start a local Anvil node:
```bash
make anvil
```

Deploy contracts locally:
```bash
make deploy
```

### Testnet
Set environment variables in a `.env` file (refer to `.env.example` for structure):
- `SEPOLIA_RPC_URL`: Sepolia network RPC endpoint.
- `PRIVATE_KEY`: Development private key with no real funds.

Deploy to Sepolia:
```bash
make deploy ARGS="--network sepolia"
```

---

## Testing

This project implements foundational test tiers:
1. **Unit Tests**
2. **Integration Tests**
3. **Fuzz Testing**

Run tests:
```bash
forge test
```

Check coverage:
```bash
forge coverage --report debug
```

---

## Additional Utilities

- **Estimate Gas**:
  ```bash
  forge snapshot
  ```
  Generates a `.gas-snapshot` file.

- **Code Formatting**:
  ```bash
  forge fmt
  ```

---

## Summary

This repository is inspired by the Cyfrin Foundry Solidity Course and extends its principles to include rigorous testing methodologies such as fuzz and invariant testing. It provides a strong foundation for developing secure and reliable DeFi projects.
