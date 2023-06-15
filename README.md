# 🔮 Trusted OffChain Oracle

The `OracleVerifier` is an abstract Solidity smart contract designed to interact securely and reliably with off-chain data in a decentralized environment. This solution provides a verification system where data, signed by trusted off-chain oracles, can be pushed to the blockchain by users interacting with the front end of the application.

In this setup, a **trusted oracle**, which could be an off-chain script or server possessing a pair of public and private keys, generates the required data along with a timestamp. The oracle then signs this payload with its private key. The users on the front end fetch this signed payload from the oracle and send it to the smart contract. The contract, which already knows the oracle's public key, verifies the authenticity of the data using the oracle's digital signature, ensuring the data's integrity and the source's trustworthiness.

This approach has several **advantages**:

- **Reduced Gas Costs**: Users only push the small, signed payload to the blockchain, which is generally cheaper than executing complex on-chain data fetching transactions.

- **Increased Flexibility and Accessibility**: Users can fetch data from any trusted oracle and push it to the blockchain, enabling the use of multiple data sources and redundancy.

While there are several oracle solutions available, such as Chainlink, this contract offers a unique and flexible approach. It allows for the use of any arbitrary oracle, as long as it can provide a valid signature for the data it's delivering, giving projects the ability to define their specific requirements for their oracles and doesn't tie them to a particular oracle service provider.

While the `OracleVerifier` implementation provides several benefits, there are a few potential **disadvantages** or challenges to this approach as well:

- **Reliance on Trusted Oracles**: In this model, it's essential to trust the oracle to provide accurate data. If an oracle behaves maliciously or is compromised, it can provide false data, which could have serious consequences for the systems relying on it. In contrast, some other oracle solutions use decentralized networks of oracles and aggregation techniques to minimize this risk.

- **Off-Chain Security**: The security and integrity of the data are heavily reliant on the security of the off-chain systems. If the private keys of the oracle are compromised, an attacker could forge data.

- **External Data Source Dependence**: The data being signed by the oracle comes from off-chain sources. If these sources experience downtime or provide inaccurate data, it can negatively affect the contract's operation.

- **Manual Intervention**: Depending on the implementation, data fetching might require manual intervention from the user, which can lead to inefficiencies and user experience challenges. Automated systems, however, can be built to streamline this process.

- **Data Freshness**: Depending on the setup, there may be delays between the oracle sourcing the data, signing it, users fetching it, and then pushing it to the smart contract. This could lead to slightly outdated data being used by the contract.

- **Scalability**: The process involves off-chain operations which could potentially become a bottleneck if the oracle is expected to provide data for a large number of requests in real-time.

## 📄 Contracts

- **OracleVerifier.sol**: This abstract contract implements core functionality for verifying data provided by off-chain oracles. It introduces concepts of trusted oracles, a time threshold for accepting data, and a way to verify the integrity of data provided by the oracle using digital signatures. It includes modifiers for restricting access to the owner and verification of data.

- **MockOracle.sol**: This contract is a mock implementation of the `OracleVerifier` contract. It is used for testing the functionality of `OracleVerifier`. The MockOracle contract introduces two sample state variables: `price and text`. These variables are publicly accessible and can be updated via the `updateData` function, but only if the data provided passes the verification process defined in `OracleVerifier`. This contract demonstrates a practical application of the OracleVerifier's verification process.

- **OracleVerifierTest.sol**: This contract is designed to test the `OracleVerifier` contract by simulating different scenarios and asserting expected behaviors. It leverages features provided by Foundry's Test library to create a comprehensive suite of tests, covering everything from initial state after deployment to potential error conditions. It has helper functions such as `signPayload` for simulating the oracle's signature generation process and `fetchPrice` for simulating real world data fetching. In the `fetchPrice` function, `vm.ffi` cheatcodes is used to fetch the latest **BTC price** from **Binance's API**. The function uses the **FFI (Foreign Function Interface)** to make a system call to `curl`, an off-chain command-line tool for transferring data with URLs. The output of this `curl` command, which contains the response from the Binance API, is then returned by `vm.ffi`. This output is parsed and used within the test cases to emulate real-world data for testing the contract's functionality. This contract provides a solid example of how to test smart contracts in Ethereum and especially those involving external data sources or "oracles".

## :wrench: Development Tools

- **Solidity**: I've used Solidity version **0.8.17** to write the smart contracts in this repository.
- **Foundry**: a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.

## :rocket: Getting Started

1. Clone this repository. `git clone https://github.com/0xValerius/trusted-offchain-oracle.git`
2. Compile the smart contracts. `forge build`
3. Run the test suite. `forge test`

## 🤖 Usage

To use the `OracleVerifier` in your project, import the contracts from the src directory. The `OracleVerifier.sol` contract is abstract and should be inherited by your own contract. A mock implementation and comprehensive tests for `OracleVerifier` are also provided for reference and testing purposes.

## :scroll: License

[MIT](https://choosealicense.com/licenses/mit/)

## 🚨 Disclaimer

The `OracleVerifier.sol` is provided "as is" and without warranties of any kind, whether express or implied. The user assumes all responsibility and risk for the use of this software.
