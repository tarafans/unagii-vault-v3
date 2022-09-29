<table style="background-color: transparent; background-image: url(https://i.ibb.co/crxZMz2/arrows-removebg-preview.png); background-position: right bottom; background-repeat: no-repeat; background-size: contain; border: 0px solid transparent; margin: 0% 0% 0% 0%; padding: 0% 0% 0% 0%; table-layout: auto; width: 100%; height: 100%">
  <tr>
    <td style="border: 0px solid transparent">
      <h1>Unagii</h1>
      <h2>Vaults v3</h2>
      <h3>Security Assessment</h3>
      <h4>October 1st, 2022</h4>
      <h4 style="color: tomato">&nbsp;</h3>
    </td>
  </tr>
  <tr style="height: 1rem">
    <td style="border: 0px solid transparent"></td>
  </tr>
  <tr>
    <td style="border: 0px solid transparent">
      <b>Audited By</b>:
      <br>
      Angelos Apostolidis <br>
      <a href="mailto:angelos.apostolidis@ourovoros.io" style="color: rgb(249, 159, 28)">angelos.apostolidis@ourovoros.io</a>
      <br>
      Sheraz Arshad <br>
      <a href="mailto:sheraz.arshad@ourovoros.io" style="color: rgb(249, 159, 28)">sheraz.arshad@ourovoros.io</a>
      <br>
    </td>
  </tr>
  <tr style="height: 6rem">
    <td style="border: 0px solid transparent"></td>
  </tr>
</table>

<div style="page-break-after: always"></div>

## <img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/> Overview

### Project Summary

<table>
  <tr>
    <td style="width: 30%"><strong><span>Project Name</span></strong></td>
    <td><span>Unagii - Vaults v3</span></td>
  </tr>
  <tr>
    <td style="width: 30%"><strong><span>Website</span></strong></td>
    <td><a href="https://www.unagii.com">Unagii</a></td>
  </tr>
  <tr>
    <td><strong><span>Description</span></strong></td>
    <td><span>Tokenized Vaults with Yield Farming Strategies</span></td>
  </tr>
  <tr>
    <td><strong><span>Platform</span></strong></td>
    <td><span>Ethereum; Solidity, Yul</span></td>
  </tr>
  <tr>
    <td><strong><span>Codebase</span></strong></td>
    <td><a href="https://github.com/stakewithus/unagii-vault-v3/"><span>GitHub Repository</span></a></td>
  </tr>
  <tr>
    <td><strong><span>Commits</span></strong></td>
    <td>
      <a href="https://github.com/stakewithus/unagii-vault-v3/commit/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19">c75afbed8c32147d827ad3d60ea0c1d07c8ecc19</a><br>
      <a href="https://github.com/stakewithus/unagii-vault-v3/commit/76dd9aeb02866439703cfa5a24cec23f67ae2733">76dd9aeb02866439703cfa5a24cec23f67ae2733</a><br>
    </td>
  </tr>
</table>

### Audit Summary

<table>
  <tr>
    <td style="width: 30%"><strong><span>Delivery Date</span></strong></td>
    <td><span>October 1st, 2022</span></td>
  </tr>
  <tr>
    <td><strong><span>Method of Audit</span></strong></td>
    <td><span>Static Analysis, Manual Review</span></td>
  </tr>
</table>

### Vulnerability Summary

<table>
  <tr>
    <td style="width: 30%"><strong><span style="background-color: transparent; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> <span>Total Issues</span></strong></td>
    <td><span>14</span></td>
  </tr>
<tr>
    <td><strong><span style="background-color: darkorange; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> <span>Total Major</span></strong></td>
    <td><span>2</span></td>
  </tr>
<tr>
    <td><strong><span style="background-color: dodgerblue; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> <span>Total Minor</span></strong></td>
    <td><span>1</span></td>
  </tr>
<tr>
    <td><strong><span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> <span>Total Informational</span></strong></td>
    <td><span>11</span></td>
  </tr>
</table>

<div style="page-break-after: always"></div>

## <img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/> Files In Scope

| Contract                    | Location                                                                                                                                                                              |
| :-------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| BlockDelay.sol              | [src/libraries/BlockDelay.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/libraries/BlockDelay.sol)                             |
| Ownable.sol                 | [src/libraries/Ownable.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/libraries/Ownable.sol)                                   |
| Ownership.sol               | [src/libraries/Ownership.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/libraries/Ownership.sol)                               |
| StrategyCompound.sol        | [src/strategies/StrategyCompound.sol](https://github.com/stakewithus/unagii-vault-v3/blob/76dd9aeb02866439703cfa5a24cec23f67ae2733/src/strategies/StrategyCompound.sol)               |
| StrategyStargate.sol        | [src/strategies/StrategyStargate.sol](https://github.com/stakewithus/unagii-vault-v3/blob/76dd9aeb02866439703cfa5a24cec23f67ae2733/src/strategies/StrategyStargate.sol)               |
| UsdcStrategyCompound.sol    | [src/strategies/UsdcStrategyCompound.sol](https://github.com/stakewithus/unagii-vault-v3/blob/76dd9aeb02866439703cfa5a24cec23f67ae2733/src/strategies/UsdcStrategyCompound.sol)       |
| UsdcStrategyConvex.sol      | [src/strategies/UsdcStrategyConvex.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvex.sol)           |
| UsdcStrategyConvexGen2.sol  | [src/strategies/UsdcStrategyConvexGen2.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvexGen2.sol)   |
| UsdcStrategyConvexGusd.sol  | [src/strategies/UsdcStrategyConvexGusd.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvexGusd.sol)   |
| UsdcStrategyConvexPax.sol   | [src/strategies/UsdcStrategyConvexPax.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvexPax.sol)     |
| UsdcStrategyStargate.sol    | [src/strategies/UsdcStrategyStargate.sol](https://github.com/stakewithus/unagii-vault-v3/blob/76dd9aeb02866439703cfa5a24cec23f67ae2733/src/strategies/UsdcStrategyStargate.sol)       |
| WbtcStrategyConvexGen2.sol  | [src/strategies/WbtcStrategyConvexGen2.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexGen2.sol)   |
| WbtcStrategyConvexPbtc.sol  | [src/strategies/WbtcStrategyConvexPbtc.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexPbtc.sol)   |
| WbtcStrategyConvexRen.sol   | [src/strategies/WbtcStrategyConvexRen.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexRen.sol)     |
| WethStrategyConvexStEth.sol | [src/strategies/WethStrategyConvexStEth.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WethStrategyConvexStEth.sol) |
| WethZap.sol                 | [src/zaps/WethZap.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/zaps/WethZap.sol)                                             |
| Strategy.sol                | [src/Strategy.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Strategy.sol)                                                     |
| Swap.sol                    | [src/Swap.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Swap.sol)                                                             |
| Vault.sol                   | [src/Vault.sol](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Vault.sol)                                                           |

<div style="page-break-after: always"></div>

## <img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/> Findings

<table style="table-layout: fixed">
  <tr style="height: 1em">
    <td style="width: 5.6em; text-align: right"><span>ID</span></td>
    <td><span>Title</span></td>
    <td style="width: 10.75em"><span>Type</span></td>
    <td style="width: 8.25em"><span>Severity</span></td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-01">F-01</a>
    </td>
    <td>Unused Custom Error</td>
    <td>Dead Code</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-02">F-02</a>
    </td>
    <td>State Variable Visibility</td>
    <td>Language Specific</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-03">F-03</a>
    </td>
    <td>Conditional Optimization</td>
    <td>Gas Optimization</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-04">F-04</a>
    </td>
    <td>Redundant Approval Reset</td>
    <td>Gas Optimization</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-05">F-05</a>
    </td>
    <td>Event Addition</td>
    <td>Language Specific</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-06">F-06</a>
    </td>
    <td>Event Addition</td>
    <td>Language Specific</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-07">F-07</a>
    </td>
    <td>Misleading Event Propagation</td>
    <td>Off-chain Tracking</td>
    <td>
      <span style="background-color: gold; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Minor
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-08">F-08</a>
    </td>
    <td>Contract Code Size</td>
    <td>Language Specific</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-09">F-09</a>
    </td>
    <td>State Variable Mutability</td>
    <td>Language Specific</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-10">F-10</a>
    </td>
    <td>State Variable Mutability</td>
    <td>Language Specific</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-11">F-11</a>
    </td>
    <td>Raw Maths</td>
    <td>Mathematical Operations</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-12">F-12</a>
    </td>
    <td>Code Optimization</td>
    <td>Gas Optimization</td>
    <td>
      <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-13">F-13</a>
    </td>
    <td>Strategy Removal Leftover Rewards</td>
    <td>Volatile Code</td>
    <td>
      <span style="background-color: darkorange; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Major
    </td>
  </tr>
  <tr>
    <td style="text-align: right">
      <a href="#F-14">F-14</a>
    </td>
    <td>Directly Receiving ETH</td>
    <td>Volatile Code</td>
    <td>
      <span style="background-color: darkorange; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Major
    </td>
  </tr>
</table>

<div style="page-break-after: always"></div>

### <a name="F-01"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-01: Unused Custom Error

| Type      | Severity                                                                                                                            | Location                                                                                                                                                                                                                                                                                                          |
| :-------- | :---------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Dead Code | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational">[Ownable.sol L9](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/libraries/Ownable.sol#L9), [L10](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/libraries/Ownable.sol#L10)</span> |

#### <span class="informational">Description:</span>

The linked custom errors are never used throughout the contract.

#### <span class="informational">Recommendation:</span>

We advise to remove the `AlreadyRole` and `NotRole` custom errors from the codebase.

#### <span class="informational">Alleviation:</span>

The team opted to consider our references and used all the custom error defined in the codebase.

<div style="page-break-after: always"></div>

### <a name="F-02"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-02: State Variable Visibility

| Type              | Severity                                                                                                                            | Location                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Language Specific | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational">[Ownership.sol L10](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/libraries/Ownership.sol#L10), [UsdcStrategyConvex L19-L21](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvex.sol#L19-L21), [UsdcStrategyConvexGen2 L19-L23](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvexGen2.sol#L19-L23), [WbtcStrategyConvexGen2 L19-L23](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexGen2.sol#L19-L23), [WbtcStrategyConvexPbtc L19-L22](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexPbtc.sol#L19-L22)</span> |

#### <span class="informational">Description:</span>

The linked variable declarations do not have a visibility specifier explicitly set.

#### <span class="informational">Recommendation:</span>

Inconsistencies in the default visibility the Solidity compilers impose can cause issues in the functionality of the codebase. We advise that visibility specifiers for the linked variables are explicitly set.

#### <span class="informational">Alleviation:</span>

The team opted to consider our references and added explicit visibility specifiers for the linked state variables.

<div style="page-break-after: always"></div>

### <a name="F-03"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-03: Conditional Optimization

| Type             | Severity                                                                                                                            | Location                                                                                                                                                                 |
| :--------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Gas Optimization | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational">[Strategy.sol L70](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Strategy.sol#L70)</span> |

#### <span class="informational">Description:</span>

The value of the `received` local variable cannot be greater than that of the `_assets` one due to the statement in [L68](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Strategy.sol#L68).

#### <span class="informational">Recommendation:</span>

We advise that the linked conditional is changed to a strict equality one.

#### <span class="informational">Alleviation:</span>

The team opted to consider our references and removed the redundant code.

<div style="page-break-after: always"></div>

### <a name="F-04"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-04: Redundant Approval Reset

| Type             | Severity                                                                                                                            | Location                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| :--------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Gas Optimization | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational"> [UsdcStrategyConvex L81](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvex.sol#L81), [UsdcStrategyConvexGen2 L89](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvexGen2.sol#L89), [WbtcStrategyConvexGen2 L89](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexGen2.sol#L89), [WbtcStrategyConvexPbtc L80](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexPbtc.sol#L80)</span> |

#### <span class="informational">Description:</span>

The external `changeSwap` function calls the internal `_approve` and `_unapprove` ones, which in turn also perform approvals that are not related to swap change.

#### <span class="informational">Recommendation:</span>

We advise that the swap-related approvals are extracted out to a separate function so only the relevant approvals are performed upon swap change.

#### <span class="informational">Alleviation:</span>

The team opted to consider our references, introduced new internal functions for the swap-related approvals and utilized those functions upon swap change.

<div style="page-break-after: always"></div>

### <a name="F-05"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-05: Event Addition

| Type              | Severity                                                                                                                            | Location                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Language Specific | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational">[Ownable.sol L18](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/libraries/Ownable.sol#L18), [Ownership L30](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/libraries/Ownership.sol#L30), [L43](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/libraries/Ownership.sol#L43)</span> |

#### <span class="informational">Description:</span>

The privileged users of the systems are updated, yet no event is emitted.

#### <span class="informational">Recommendation:</span>

We advise that the linked functions emit events, signifying an address role change.

#### <span class="informational">Alleviation:</span>

The team opted to consider our references for the majority of the referenced exhibits and introduced events related to role change. The team has acknowledged the last exhibit and decided to follow the suggested pattern only for the `owner` role.

<div style="page-break-after: always"></div>

### <a name="F-06"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-06: Event Addition

| Type              | Severity                                                                                                                            | Location                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Language Specific | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational">[Strategy.sol L88](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Strategy.sol#L88), [L98](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Strategy.sol#L98), [Vault L314](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Vault.sol#L314), [L353](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Vault.sol#L353)</span> |

#### <span class="informational">Description:</span>

The system's values are updated, yet no event is emitted.

#### <span class="informational">Recommendation:</span>

We advise that the linked functions emit events, signifying a change in the user-related values.

#### <span class="informational">Alleviation:</span>

The team opted to consider our references and introduced events related to user-centered values.

<div style="page-break-after: always"></div>

### <a name="F-07"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-07: Misleading Event Propagation

| Type               | Severity                                                                                                               | Location                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| :----------------- | :--------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Off-chain Tracking | <span style="background-color: gold; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Minor | <span class="medium">[WethZap.sol L26](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/zaps/WethZap.sol#L26), [L33](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/zaps/WethZap.sol#L33), [L43](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/zaps/WethZap.sol#L43), [L54](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/zaps/WethZap.sol#L54)</span> |

#### <span class="medium">Description:</span>

The value of `msg.sender` in the aforementioned events emitted in the vault contract will always be that of the zapper instead of an EOA, while the zapper does not emit any similar event. This can lead to inconsistencies to the off-chain services that keep track of the on-chain data.

#### <span class="medium">Recommendation:</span>

We advise that the linked events are revised.

#### <span class="medium">Alleviation:</span>

The team opted to consider our references and introduced new events to the zapper contract, allowing for better off-chain tracking.

<div style="page-break-after: always"></div>

### <a name="F-08"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-08: Contract Code Size

| Type              | Severity                                                                                                                            | Location                                                                                                                                                           |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Language Specific | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational">[Vault.sol L13](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Vault.sol#L13)</span> |

#### <span class="informational">Description:</span>

The linked contract's code size may exceed the limit introduced in the Spurious Dragon fork, which may not allow its deployment on mainnet.

#### <span class="informational">Recommendation:</span>

We advise using the correct optimizer values.

#### <span class="informational">Alleviation:</span>

The development team has acknowledged this exhibit.

<div style="page-break-after: always"></div>

### <a name="F-09"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-09: State Variable Mutability

| Type              | Severity                                                                                                                            | Location                                                                                                                                                                 |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Language Specific | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational">[Strategy.sol L21](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Strategy.sol#L21)</span> |

#### <span class="informational">Description:</span>

The linked variable is assigned to only once during the `constructor`'s execution.

#### <span class="informational">Recommendation:</span>

We advise that the `immutable` mutability specifier is set at the variable's contract-level declaration to greatly optimize the gas cost of utilizing the variables.

#### <span class="informational">Alleviation:</span>

The development team has introduced a new setter function in the codebase, rendering this exhibit invalid.

<div style="page-break-after: always"></div>

### <a name="F-10"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-10: State Variable Mutability

| Type              | Severity                                                                                                                            | Location                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Language Specific | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational">[UsdcStrategyConvex.sol L25](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvex.sol#L25), [UsdcStrategyConvexGen2 L27](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvexGen2.sol#L27), [WbtcStrategyConvexGen2 L25](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexGen2.sol#L25), [WbtcStrategyConvexPbtc L24](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexPbtc.sol#L24), [WbtcStrategyConvexRen L28](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexRen.sol#L28), [WethStrategyConvexStEth L30](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WethStrategyConvexStEth.sol#L30)</span> |

#### <span class="informational">Description:</span>

The linked variables are assigned to only once during their contract-level declaration.

#### <span class="informational">Recommendation:</span>

We advise that the `constant` keyword is introduced in the variable declaration to greatly optimize the gas cost involved in utilizing the variable.

#### <span class="informational">Alleviation:</span>

The development team has introduced a new setter function in the codebase, rendering this exhibit invalid.

<div style="page-break-after: always"></div>

### <a name="F-11"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-11: Raw Maths

| Type                    | Severity                                                                                                                            | Location                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| :---------------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Mathematical Operations | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational">[UsdcStrategyConvexGen2.sol L114](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/UsdcStrategyConvexGen2.sol#L114), [WbtcStrategyConvexGen2 L114](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexGen2.sol#L114), [WbtcStrategyConvexPbtc L105](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexPbtc.sol#L105), [WbtcStrategyConvexRen L95](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WbtcStrategyConvexRen.sol#L95), [WethStrategyConvexStEth L99](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/strategies/WethStrategyConvexStEth.sol#L99)</span> |

#### <span class="informational">Description:</span>

The linked statements omit the use of the `mulDivDown` function from the `FixedPointMathLib` library.

#### <span class="informational">Recommendation:</span>

We advise that the aforementioned statements utilize the said function instead of using raw mathematical operations.

#### <span class="informational">Alleviation:</span>

The team opted to consider our references and utilized the related functionality exposed from the `FixedPointMathLib` library.

<div style="page-break-after: always"></div>

### <a name="F-12"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-12: Code Optimization

| Type             | Severity                                                                                                                            | Location                                                                                                                                                             |
| :--------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Gas Optimization | <span style="background-color: limegreen; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Informational | <span class="informational">[Vault.sol L107](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Vault.sol#L107)</span> |

#### <span class="informational">Description:</span>

The linked function contain explicitly named `return` variables that is not utilized within the function's code block.

#### <span class="informational">Recommendation:</span>

We advise that the linked variable are either utilized or omitted from the declaration.

#### <span class="informational">Alleviation:</span>

The team has acknowledged this exhibit but decided to not apply its remediation in the current version of the codebase.

<div style="page-break-after: always"></div>

### <a name="F-13"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-13: Strategy Removal Leftover Rewards

| Type          | Severity                                                                                                                     | Location                                                                                                                                                     |
| :------------ | :--------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Volatile Code | <span style="background-color: darkorange; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Major | <span class="major">[Vault.sol L271](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/Vault.sol#L271)</span> |

#### <span class="major">Description:</span>

The linked function should be harvesting any rewards before removing the strategy from the vault contract since only the vault is allowed to harvest a strategy's rewards. Also, the edge case where a debt is zero but rewards are still available should be taken into account.

#### <span class="major">Recommendation:</span>

We advise either assuring that no rewards are available to harvest or performing a final harvest before the strategy removal. Also, in case that edge case is still valid, the reward collection should be irrespective of a strategy's debt.

#### <span class="major">Alleviation:</span>

The development team has acknowledged this exhibit and decided to inform the related privileged users for the edge case.

<div style="page-break-after: always"></div>

### <a name="F-14"><img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/></a> F-14: Directly Receiving Ether

| Type          | Severity                                                                                                                     | Location                                                                                                                                                            |
| :------------ | :--------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Volatile Code | <span style="background-color: darkorange; border-radius: 50%; display: inline-block; height: 8pt; width: 8pt"></span> Major | <span class="major">[WethZap.sol L20](https://github.com/stakewithus/unagii-vault-v3/blob/c75afbed8c32147d827ad3d60ea0c1d07c8ecc19/src/zaps/WethZap.sol#L20)</span> |

#### <span class="major">Description:</span>

The empty `receive` function allows for arbitrary Ether transfer to the `WethZap` contract, which in turn will be locked as the said contract does not implement any direct Ether withdraw functionality.

#### <span class="major">Recommendation:</span>

We advise adding a check to allow only the `WETH9` contract to send Ether and disallowing any arbitrary Ether transfers to the contract.

#### <span class="major">Alleviation:</span>

The team opted to consider our references and introduced a `require` statement that only allows the `WETH9` contract to send Ether to the zapper, rendering any arbitrary Ether transfers to it invalid.

## <img src="https://i.ibb.co/NFtf2HY/logo-removebg-preview.png" style="height: 28pt; filter: invert(0)"/> Disclaimer

Reports made by Ourovoros are not to be considered as a recommendation or approval of any particular project or team. Security reviews made by Ourovoros for any project or team are not to be taken as a depiction of the value of the “product” or “asset” that is being reviewed.

Ourovoros reports are not to be considered as a guarantee of the bug-free nature of the technology analyzed and should not be used as an investment decision with any particular project. They represent an extensive auditing process intending to help our customers increase the quality of their code while reducing the high level of risk presented by cryptographic tokens and blockchain technology.

Each company and individual is responsible for their own due diligence and continuous security. Our goal is to help reduce the attack parameters and the high level of variance associated with utilizing new and consistently changing technologies, and in no way claim any guarantee of security or functionality of the technology we agree to analyze.
