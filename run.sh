#!/bin/bash

# Generate runtime information directly from the solidity contract
kevm solc-to-k ERC20.sol ERC20 --pyk --main-module ERC20-VERIFICATION --verbose > erc20-bin-runtime.k

# Kompile everything
kevm kompile erc20-spec.md --pyk --target haskell --syntax-module VERIFICATION --main-module VERIFICATION --output-definition erc20-spec/haskell --verbose

# Prove it
kevm prove erc20-spec.md --backend haskell --definition erc20-spec/haskell --pyk --claim ERC20-SPEC.approve.success --verbose