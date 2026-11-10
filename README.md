# SFT-Lock

**Reference smart-contract implementation for _Blockchain-Based Spectrum Resource Securitization via Semi-Fungible Token-Lock_.**

> **Research prototype — not audited.** The contracts are provided for academic study and experimental evaluation only. Do not deploy them to a production network, use real funds, or manage real spectrum assets without a thorough security review and additional engineering.

## Overview

SFT-Lock explores blockchain-based securitization and sharing of spectrum resources. Its central idea is to use **lock/unlock state transitions** instead of repeatedly minting and burning asset-representation tokens. This approach is intended to preserve the identity and traceability of the underlying non-fungible spectrum asset while supporting fractional interests and transfers.

The accompanying paper evaluates the proposed mechanism against an ERC-404-style hybrid-token approach, including gas-cost measurements on a private Ethereum network. **The current repository contains the research smart contracts; it does not yet include the full experiment scripts, deployment configuration, or benchmark data required to independently reproduce those results.**

## Paper

*Blockchain-Based Spectrum Resource Securitization via Semi-Fungible Token-Lock* (2026).

- arXiv: [2601.15594](https://arxiv.org/abs/2601.15594)
- DOI (arXiv): [10.48550/arXiv.2601.15594](https://doi.org/10.48550/arXiv.2601.15594)

## Repository structure

```text
SFT-Lock/
├── SMA.sol          # Spectrum management and base-asset registration
├── NDASP.sol        # Securitization, lock/unlock, and fractional-token logic
├── PU.sol           # Primary-user interactions and rental-right logic
├── interface/
│   ├── ISMA.sol     # Interface used by other contracts
│   └── INDASP.sol   # Interface used by PU.sol
└── README.md
```

The contract names and interfaces follow the terminology used in the research implementation:

| Contract | Role |
| --- | --- |
| `SMA` | Registers spectrum-related assets and manages primary-user information and NFST records. |
| `NDASP` | Implements asset securitization, token-state management, and the SFT-Lock lock/unlock mechanism. |
| `PU` | Models primary-user activities, including rental-right tokens and related transactions. |

These contracts are **research-specific representations**; they are not claimed to be drop-in implementations of established ERC token standards.

## Core concepts

- **NFST:** A non-fungible representation of an underlying spectrum asset.
- **SNFST:** A securitized non-fungible representation used in the SFT-Lock mechanism.
- **SFST:** A fungible or fractional interest associated with the securitization process.
- **RNFST:** A token representation used by the rental-right functionality in `PU.sol`.
- **Lock/unlock:** State transitions intended to support changes in fractional ownership while retaining the identity of the associated non-fungible asset.

For formal definitions, assumptions, and experimental interpretation, refer to the paper.

## Getting started (local research use)

### Prerequisites

- Git
- A Solidity compiler compatible with `pragma solidity ^0.8.0`
- A local Ethereum-compatible development environment or an IDE such as [Remix](https://remix.ethereum.org/)

The repository currently does **not** include a Hardhat or Foundry project configuration. The following steps describe the intended contract dependencies, not a verified end-to-end deployment tutorial.

### Obtain the source

```bash
git clone https://github.com/powtime/SFT-Lock.git
cd SFT-Lock
```

### Compile and deploy on a local development chain

1. Import the Solidity sources into your chosen environment, preserving the `interface/` directory and relative imports.
2. Compile the contracts using a compatible Solidity 0.8.x compiler.
3. Deploy `SMA` (no constructor parameters).
4. Deploy `NDASP`, passing the deployed `SMA` address as `_smaContractAddress`.
5. From the owner of `SMA`, call `SMA.setNDASP(<NDASP address>)` to configure the authorized NDASP contract.
6. Deploy `PU`, passing the `SMA` and `NDASP` addresses as `_smaContractAddress` and `_ndaspContractAddress`.
7. Use **test accounts and test assets only** to inspect registration, state transitions, and rental-related functions.

**Important:** Compilation, deployment, and runtime behavior have not been independently validated as part of this README. Security-sensitive transactions should not be exercised with real assets.

## Reproducing the paper

The paper describes functional experiments and gas-cost comparisons. To reproduce these measurements independently, a future release should specify:

1. Exact Solidity compiler and EVM versions, optimization settings, and development-chain configuration.
2. Contract deployment and initial-state setup, including actors and spectrum-asset inputs.
3. Transaction sequences for minting, staking, locking, unlocking, transfer, and rental operations.
4. Baseline implementation and identical workload definitions for the ERC-404-style comparison.
5. Scripts, raw gas receipts, and instructions for regenerating the reported tables or figures.

**Status:** These reproduction materials have not yet been included in the public repository. No claim of fully automated paper reproduction is made for the current version.

## Security and limitations

This project is a **proof of concept**, not production-ready financial or spectrum-management infrastructure.

- The smart contracts have **not** been independently security-audited.
- Some authorization and value-handling paths require additional review and remediation.
- No production deployment, economic safety, regulatory compliance, or spectrum-use authorization is implied.
- Experimental results in the paper should not be interpreted as guarantees for other workloads or networks.

Security reports and reproducible issues can be submitted through GitHub Issues. Please do not include real credentials, private keys, or sensitive account information.

## Citation

If you use this implementation in academic work, please cite the associated paper:

```bibtex
@misc{zhou2026sftlock,
  title         = {Blockchain-Based Spectrum Resource Securitization via Semi-Fungible Token-Lock},
  author        = {Zhou, Zhixian and Chen, Bin and Peng, Zhe and Liang, Zhiming and Wu, Ruijun and Sun, Chen and Wang, Shuo},
  year          = {2026},
  eprint        = {2601.15594},
  archivePrefix = {arXiv},
  primaryClass  = {cs.IR},
  doi           = {10.48550/arXiv.2601.15594},
  url           = {https://arxiv.org/abs/2601.15594}
}
```

For an exact software version, also cite the relevant Git commit or a future archived release DOI when available.

## Contributors and license

The paper authors are listed above. Source-code development contributions can be reviewed in the [commit history](https://github.com/powtime/SFT-Lock/commits/master); a dedicated contributor list can be added after confirmation by the project team.

The Solidity source files carry `SPDX-License-Identifier: MIT` headers. A repository-level `LICENSE` file has not yet been added; the maintainers should confirm the applicable rights and add an explicit license before presenting the repository as a fully licensed open-source distribution.
