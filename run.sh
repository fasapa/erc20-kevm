#!/bin/bash 

set -euxo pipefail 
         
build() { 
    # Generate runtime information directly from the solidity contract
    kevm solc-to-k ERC20.sol ERC20 --pyk --main-module ERC20-VERIFICATION --verbose > erc20-bin-runtime.k
         
    # Kompile everything
    kevm kompile ${spec} --pyk --target haskell --syntax-module VERIFICATION --main-module VERIFICATION --output-definition ${definition} --verbose
}         
         
prove() { 
    # Prove it
    kevm prove ${spec} --backend haskell --definition ${definition} --pyk --claim ${claim} --verbose --save-directory proofs "$@"
}

view() {
    # Prove it
    kevm view-kcfg ${spec} --definition ${definition} --claim ${claim} --verbose --save-directory proofs "$@"
}

spec=erc20-spec.md
definition=erc20-spec/haskell
claim=ERC20-SPEC.approve.success

# build
# prove
view

# #!/bin/bash

# # Generate runtime information directly from the solidity contract
# kevm solc-to-k ERC20.sol ERC20 --pyk --main-module ERC20-VERIFICATION --verbose > erc20-bin-runtime.k

# # Kompile everything
# kevm kompile erc20-spec.md --pyk --target haskell --syntax-module VERIFICATION --main-module VERIFICATION --output-definition erc20-spec/haskell --verbose

# # Prove it
# kevm prove erc20-spec.md --backend haskell --definition erc20-spec/haskell --pyk --claim ERC20-SPEC.approve.success --verbose