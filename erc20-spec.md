ERC20-ish Verification
======================

```k
requires "edsl.md"
requires "optimizations.md"
requires "lemmas/lemmas.k"
```

Solidity Code
-------------

File [`ERC20.sol`](ERC20.sol) contains some code snippets we want to verify the functional correctness of.
Call `kevm solc-to-k ERC20.sol ERC20 --pyk --main-module ERC20-VERIFICATION > erc20-bin-runtime.k `, to generate the helper K files.

Verification Module
-------------------

Helper module for verification tasks.

-   Add any lemmas needed for our proofs.
-   Import a large body of existing lemmas from KEVM.

```k
requires "erc20-bin-runtime.k"

module VERIFICATION
    imports EDSL
    imports LEMMAS
    imports EVM-OPTIMIZATIONS
    imports ERC20-VERIFICATION

    syntax Step ::= Bytes | Int
    syntax KItem ::= runLemma ( Step ) | doneLemma ( Step )
 // -------------------------------------------------------
    rule <k> runLemma(S) => doneLemma(S) ... </k>

 // decimals lemmas
 // ---------------

    rule         255 &Int X <Int 256 => true requires 0 <=Int X [simplification, smt-lemma]
    rule 0 <=Int 255 &Int X          => true requires 0 <=Int X [simplification, smt-lemma]

endmodule
```

K Specifications
----------------

Formal specifications (using KEVM) of the correctness properties for our Solidity code.

```k
module ERC20-SPEC
    imports VERIFICATION
```

### Functional Claims

```k
    claim <k> runLemma(#bufStrict(32, #loc(ERC20._allowances[OWNER]))) => doneLemma(#buf(32, keccak(#buf(32, OWNER) +Bytes #buf(32, 1)))) ... </k>
      requires #rangeAddress(OWNER)
```

### Calling decimals() works

-   Everything from `<mode>` to `<callValue>` is boilerplate.
-   We are setting `<callData>` to `decimals()`.
-   We ask the prover to show that in all cases, we will end in `EVMC_SUCCESS` (rollback) when this happens.
-   The `<output>` cell specifies that we it must return 18.

```k
    claim [decimals]:
          <mode>     NORMAL   </mode>
          <schedule> ISTANBUL </schedule>

          <callStack> .List                                      </callStack>
          <program>   #binRuntime(ERC20)                         </program>
          <jumpDests> #computeValidJumpDests(#binRuntime(ERC20)) </jumpDests>

          <id>         CONTRACT_ID         </id> // CONTRACT ID
          <localMem>   .Bytes        => ?_ </localMem>
          <memoryUsed> 0             => ?_ </memoryUsed>
          <wordStack>  .WordStack    => ?_ </wordStack>
          <pc>         0             => ?_ </pc>
          <gas>        #gas(_VGAS)   => ?_ </gas>
          <callValue>  0             => ?_ </callValue>

          <callData>   ERC20.decimals()               </callData>
          <k>          #execute => #halt ...          </k>
          <output>     .Bytes   => #buf(32, 18)        </output>
          <statusCode> _        => EVMC_SUCCESS       </statusCode>

          <account>
            <acctID> CONTRACT_ID </acctID>
            ...
          </account>

```

### Calling totalSupply() works

-   Everything from `<mode>` to `<callValue>` is boilerplate.
-   We are setting `<callData>` to `totalSupply()`.
-   We ask the prover to show that in all cases, we will end in `EVMC_SUCCESS` (rollback) when this happens.
-   The `<output>` cell specifies that we correctly lookup the `TS` value from the account storage.


```k
    claim [totalSupply]:
          <mode>     NORMAL   </mode>
          <schedule> ISTANBUL </schedule>

          <callStack> .List                                      </callStack>
          <program>   #binRuntime(ERC20)                         </program>
          <jumpDests> #computeValidJumpDests(#binRuntime(ERC20)) </jumpDests>

          <id>         CONTRACT_ID => ?_ </id>
          <localMem>   .Bytes      => ?_ </localMem>
          <memoryUsed> 0           => ?_ </memoryUsed>
          <wordStack>  .WordStack  => ?_ </wordStack>
          <pc>         0           => ?_ </pc>
          <gas>        #gas(_VGAS) => ?_ </gas>
          <callValue>  0           => ?_ </callValue>

          <callData>   ERC20.totalSupply()               </callData>
          <k>          #execute => #halt ...             </k>
          <output>     .Bytes   => #buf(32, ?SUPPLY) </output>
          <statusCode> _        => EVMC_SUCCESS          </statusCode>

          <account>
            <acctID> CONTRACT_ID </acctID>
            <storage> CONTRACT_STORAGE </storage>
            ...
          </account>

       requires TOTALSUPPLY_KEY ==Int #loc(ERC20._totalSupply)
        andBool TOTALSUPPLY     ==Int #lookup(CONTRACT_STORAGE, TOTALSUPPLY_KEY)
        andBool #rangeUInt(256, TOTALSUPPLY)
       ensures  #rangeUInt(256, ?SUPPLY)
        andBool (TOTALSUPPLY ==Int ?SUPPLY)
        
```

### Calling balanceOf() works

```k
    claim [balanceOf.v1]:
          <mode>     NORMAL   </mode>
          <schedule> ISTANBUL </schedule>

          <callStack> .List                                      </callStack>
          <program>   #binRuntime(ERC20)                         </program>
          <jumpDests> #computeValidJumpDests(#binRuntime(ERC20)) </jumpDests>
          <static>    false                                      </static>

          <id>         CONTRACT_ID </id>
          <localMem>   .Bytes      => ?_ </localMem>
          <memoryUsed> 0           => ?_ </memoryUsed>
          <wordStack>  .WordStack  => ?_ </wordStack>
          <pc>         0           => ?_ </pc>
          <gas>        #gas(_VGAS) => ?_ </gas>
          <callValue>  0           => ?_ </callValue>
          <substate> _             => ?_ </substate>

          <callData>   ERC20.balanceOf(ACCOUNT : address)    </callData>
          <k>          #execute => #halt ...                 </k>
          <output>     .Bytes   => #buf(32, ACCOUNT_BALANCE) </output>
          <statusCode> _        => EVMC_SUCCESS     </statusCode>

          <account>
            <acctID> CONTRACT_ID </acctID>
            <storage> CONTRACT_STORAGE </storage>
            ...
          </account>

       requires ACCOUNT_BALANCE_KEY ==Int #loc(ERC20._balances[ACCOUNT])
        andBool ACCOUNT_BALANCE     ==Int #lookup(CONTRACT_STORAGE, ACCOUNT_BALANCE_KEY)
```

```k
    claim [balanceOf.v2]:
          <mode>     NORMAL   </mode>
          <schedule> ISTANBUL </schedule>

          <callStack> .List                                      </callStack>
          <program>   #binRuntime(ERC20)                         </program>
          <jumpDests> #computeValidJumpDests(#binRuntime(ERC20)) </jumpDests>
          <static>    false                                      </static>

          <id>         CONTRACT_ID </id>
          <localMem>   .Bytes      => ?_ </localMem>
          <memoryUsed> 0           => ?_ </memoryUsed>
          <wordStack>  .WordStack  => ?_ </wordStack>
          <pc>         0           => ?_ </pc>
          <gas>        #gas(_VGAS) => ?_ </gas>
          <callValue>  0           => ?_ </callValue>
          <substate> _             => ?_ </substate>

          <callData>   ERC20.balanceOf(ACCOUNT : address)    </callData>
          <k>          #execute => #halt ...                 </k>
          <output>     .Bytes   => #buf(32, ?BAL) </output>
          <statusCode> _        => EVMC_SUCCESS     </statusCode>

          <account>
            <acctID> CONTRACT_ID </acctID>
            <storage> CONTRACT_STORAGE </storage>
            ...
          </account>

       requires ACCOUNT_BALANCE_KEY ==Int #loc(ERC20._balances[ACCOUNT])
        andBool ACCOUNT_BALANCE     ==Int #lookup(CONTRACT_STORAGE, ACCOUNT_BALANCE_KEY)
       ensures  ACCOUNT_BALANCE     ==Int ?BAL
```

### Calling Approve works
```k
    claim [approve.success]:
          <mode>     NORMAL   </mode>
          <schedule> ISTANBUL </schedule>

          <callStack> .List                                      </callStack>
          <program>   #binRuntime(ERC20)                         </program>
          <jumpDests> #computeValidJumpDests(#binRuntime(ERC20)) </jumpDests>
          <static>    false                                      </static>

          <id>         CONTRACT_ID       </id>
          <caller>     CALLER_ID         </caller>
          <localMem>   .Bytes      => ?_ </localMem>
          <memoryUsed> 0           => ?_ </memoryUsed>
          <wordStack>  .WordStack  => ?_ </wordStack>
          <pc>         0           => ?_ </pc>
          <gas>        #gas(_VGAS) => ?_ </gas>
          <callValue>  0           => ?_ </callValue>
          <substate>
            <log> // from substate
              _:List (.List => ListItem(#abiEventLog(CONTRACT_ID, "Approval", #indexed(#address(CALLER_ID)), #indexed(#address(SPENDER)), #uint256(AMOUNT))))
            </log>
            <selfDestruct>     _       </selfDestruct>
            <refund>           _ => ?_ </refund>
            <accessedAccounts> _ => ?_ </accessedAccounts>
            <accessedStorage>  _ => ?_ </accessedStorage>
          </substate>

          <callData>   ERC20.approve(SPENDER : address , AMOUNT : uint256) </callData>
          <k>          #execute => #halt ...                               </k>
          <output>     .Bytes   => #buf(32, bool2Word(true))               </output>
          <statusCode> _        => EVMC_SUCCESS                            </statusCode>

          <account>
            <acctID> CONTRACT_ID </acctID>
            <storage> CONTRACT_STORAGE => CONTRACT_STORAGE [ ALLOWANCE_KEY <- AMOUNT ] </storage>
            ...
          </account>

       requires ALLOWANCE_KEY ==Int #loc(ERC20._allowances[CALLER_ID][SPENDER])
        andBool #rangeAddress(CALLER_ID) // necessary? Because it comes from <caller></caller>
        andBool #rangeAddress(SPENDER)
        andBool #rangeUInt(256, AMOUNT)
        andBool CALLER_ID =/=Int 0
        andBool SPENDER =/=Int 0
```

```k
    claim [approve.revert]:
          <mode>     NORMAL   </mode>
          <schedule> ISTANBUL </schedule>

          <callStack> .List                                      </callStack>
          <program>   #binRuntime(ERC20)                         </program>
          <jumpDests> #computeValidJumpDests(#binRuntime(ERC20)) </jumpDests>
          <static>    false                                      </static>

          <id>         CONTRACT_ID       </id>
          <caller>     CALLER_ID         </caller>
          <localMem>   .Bytes      => ?_ </localMem>
          <memoryUsed> 0           => ?_ </memoryUsed>
          <wordStack>  .WordStack  => ?_ </wordStack>
          <pc>         0           => ?_ </pc>
          <gas>        #gas(_VGAS) => ?_ </gas>
          <callValue>  0           => ?_ </callValue>
          <substate>
            <log>              _       </log> // Since it will revert we don't expect changes to the log
            <selfDestruct>     _       </selfDestruct>
            <refund>           _ => ?_ </refund>
            <accessedAccounts> _ => ?_ </accessedAccounts>
            <accessedStorage>  _ => ?_ </accessedStorage>
          </substate>

          <callData>   ERC20.approve(SPENDER : address , AMOUNT : uint256) </callData>
          <k>          #execute => #halt ...                               </k>
          <output>     .Bytes   => ?_                                      </output>
          <statusCode> _        => EVMC_REVERT                             </statusCode>

          <account>
            <acctID> CONTRACT_ID </acctID>
            <storage> _CONTRACT_STORAGE </storage>
            ...
          </account>

       requires #rangeAddress(CALLER_ID)
        andBool #rangeAddress(SPENDER)
        andBool #rangeUInt(256, AMOUNT)
        andBool (CALLER_ID ==Int 0 orBool SPENDER ==Int 0)
```

```k
    // claim [transfer]:
    //       <mode>     NORMAL   </mode>
    //       <schedule> ISTANBUL </schedule>

    //       <callStack> .List                                      </callStack>
    //       <program>   #binRuntime(ERC20)                         </program>
    //       <jumpDests> #computeValidJumpDests(#binRuntime(ERC20)) </jumpDests>
    //       <static>    false                                      </static>

    //       <id>         CONTRACT_ID => ?_ </id>                   // contract owner
    //       <caller>     FROM_ID     => ?_ </caller>               // contract caller
    //       <localMem>   .Bytes      => ?_ </localMem>
    //       <memoryUsed> 0           => ?_ </memoryUsed>
    //       <wordStack>  .WordStack  => ?_ </wordStack>
    //       <pc>         0           => ?_ </pc>
    //       <gas>        #gas(_VGAS) => ?_ </gas>
    //       <callValue>  0           => ?_ </callValue>
    //       <substate> _             => ?_ </substate>

    //       <callData>   ERC20.transfer(TO_ID : address , AMOUNT : uint256) </callData>
    //       <k>          #execute   => #halt ...        </k>
    //       <output>     _          => #buf(32, 1)      </output>
    //       <statusCode> _          => EVMC_SUCCESS     </statusCode>

    //       <accounts>  
    //         <account>
    //           <acctID> CONTRACT_ID </acctID>
    //           <storage> CONTRACT_STORAGE [FROM_BAL_KEY <- (FROM_BALANCE => FROM_BALANCE -Int AMOUNT)] [TO_BAL_KEY <- (TO_BALANCE => TO_BALANCE +Int AMOUNT)] </storage>
    //           ...
    //         </account>
    //         <account>
    //           <acctID> FROM_ID </acctID>
    //           <storage> _FROM_STORAGE </storage>
    //           ...
    //         </account>
    //         <account>
    //           <acctID> TO_ID </acctID>
    //           <storage> _TO_STORAGE </storage>
    //           ...
    //         </account>
    //       </accounts>

    //    requires #loc(ERC20._balances[FROM_ID]) ==Int FROM_BAL_KEY andBool #lookup(CONTRACT_STORAGE, FROM_BAL_KEY) ==Int FROM_BALANCE 
    //     andBool #loc(ERC20._balances[TO_ID]) ==Int TO_BAL_KEY  andBool #lookup(CONTRACT_STORAGE, TO_BAL_KEY) ==Int TO_BALANCE
    //     andBool AMOUNT <=Int FROM_BALANCE
    //     andBool #rangeUInt(256, TO_BALANCE +Int AMOUNT)
    //     andBool #rangeAddress(CONTRACT_ID)
    //     andBool #rangeAddress(FROM_ID)
    //     andBool #rangeAddress(TO_ID)
    //     andBool #rangeUInt(256, AMOUNT)
    //     andBool CONTRACT_ID =/=Int 0
    //     andBool FROM_ID =/=Int 0
    //     andBool TO_ID =/=Int 0
```

```k
endmodule
```
