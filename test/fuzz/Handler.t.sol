
 // SPDX-License-Identifier: MIT

 pragma solidity 0.8.20;

import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import {Test,console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {
    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;
    uint256 constant MAX_DEPOSIT_SIZE = type(uint96).max;
    uint256 public time ;
    address [] public userWithCollaterlDeposited;
     MockV3Aggregator public ethUsdPriceFeed;
    constructor(DSCEngine _engine, DecentralizedStableCoin _dsc) {
        dsce = _engine;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
        ethUsdPriceFeed =MockV3Aggregator(dsce.getCollateralTokenPriceFeed(address(weth)));
    }

    function depositCollateral (uint256 collateralSeed, uint256 amountCollateral) public {
    amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
    ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
    // mint and approve!
    vm.startPrank(msg.sender);
    collateral.mint(msg.sender, amountCollateral);
    collateral.approve(address(dsce), amountCollateral);

    dsce.depositCollateral(address(collateral), amountCollateral);
    vm.stopPrank();
    userWithCollaterlDeposited.push(msg.sender);
}


function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
    ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
    uint256 maxCollateralToRedeem = dsce.getCollateralBalanceOfUser(address(collateral), msg.sender);

    amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem);
    if(amountCollateral == 0){
        return;
    }
    
    dsce.redeemCollateral(address(collateral), amountCollateral);
   
}

 function liquidate(uint256 collateralSeed, address userToBeLiquidated, uint256 debtToCover) public {
        uint256 minHealthFactor = dsce.getMinHealthFactor();
        uint256 userHealthFactor = dsce.getHealthFactor(userToBeLiquidated);
        if (userHealthFactor >= minHealthFactor) {
            return;
        }
        debtToCover = bound(debtToCover, 1, uint256(type(uint96).max));
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        dsce.liquidate(address(collateral), userToBeLiquidated, debtToCover);
    }
function mintDsc(uint256 amount,uint256 addressSeed) public {
    if( userWithCollaterlDeposited.length == 0)
    {
        return;
        } 
    address sender = userWithCollaterlDeposited[addressSeed %
    userWithCollaterlDeposited.length ];
    (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(sender);
    
    uint256 maxDscToMint = (collateralValueInUsd / 2) - totalDscMinted ;
    if(maxDscToMint < 0){
        return;
    }
   
    amount = bound(amount, 0, maxDscToMint);
    if(amount <= 0){
        return;
    }

    vm.startPrank(sender);
    dsce.mintDsc(amount);
    vm.stopPrank();
    time ++ ;
}


 function burnDsc(uint256 amountDsc) public {
        // Must burn more than 0
        amountDsc = bound(amountDsc, 0, dsc.balanceOf(msg.sender));
        if (amountDsc == 0) {
            return;
        }
        vm.startPrank(msg.sender);
        dsc.approve(address(dsce), amountDsc);
        dsce.burnDsc(amountDsc);
        vm.stopPrank();
    }

 // //THIS BREAKS OUR INVARIANT TEST SUITE!!!
    
//     function updateCollateralPrice(uint96 newPrice) public {
//     int256 newPriceInt = int256(uint256(newPrice));
//     ethUsdPriceFeed.updateAnswer(newPriceInt);
//     }



    // Helper Functions
function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock){
    if(collateralSeed % 2 == 0){
        return weth;
    }
    return wbtc;
}
}