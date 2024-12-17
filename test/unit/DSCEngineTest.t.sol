// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    address weth;
    address wbtc;
    address ethUsdPriceFeed;
    address wbtcUsdPriceFeed;
    address public USER = makeAddr("user");
     address public USER2 = makeAddr("user2");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant amountToMint = 100 ether;
     int256 public constant New_ETH_USD_PRICE = 18e8;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed,wbtcUsdPriceFeed, weth,wbtc,) = config.activeNetworkConfig();
         ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
         ERC20Mock(wbtc).mint(USER, STARTING_ERC20_BALANCE);
         ERC20Mock(weth).mint(USER2, 11*STARTING_ERC20_BALANCE);
         ERC20Mock(wbtc).mint(USER2, STARTING_ERC20_BALANCE);
    }


     ///////////////////////
    // Constructor Tests //
    ///////////////////////
    address[] public tokenAddresses;
    address[] public feedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        feedAddresses.push(ethUsdPriceFeed);
        feedAddresses.push(wbtcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch.selector);
        new DSCEngine(tokenAddresses, feedAddresses, address(dsc));
    }

    /////////////////
    // Price Tests //
    /////////////////

    function testGetUsdValue() public view {
        // 15e18 * 2,000/ETH = 30,000e18
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

 function testGetTokenAmountFromUsd() public view {
        // If we want $100 of WETH @ $2000/WETH, that would be 0.05 WETH
        uint256 expectedWeth = 0.05 ether;
        uint256 amountWeth = dsce.getTokenAmountFromUsd(weth, 100 ether);
        assertEq(amountWeth, expectedWeth);
    }
    /////////////////////////////
    // depositCollateral Tests //
    /////////////////////////////

 modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }
    function testRevertsIfCollateralZero() public  {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }
     function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock randToken = new ERC20Mock("RAN", "RAN", USER, 100e18);
        randToken.approve(address(dsce), AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__TokenNotAllowed.selector, address(randToken)));
        dsce.depositCollateral(address(randToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }
    function testCanDepositedCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
        uint256 expectedDepositedAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, 0);
        assertEq(expectedDepositedAmount, AMOUNT_COLLATERAL);
    }
     /////////////////////////////
    // Mint Tests //
    /////////////////////////////

    function testRevertMintWith_BreaksHealthFactor()public{
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector,0));
        dsce.mintDsc(amountToMint);
        vm.stopPrank();
    }

    function testCanMintDSC () public depositedCollateral{
         vm.startPrank(USER);
         dsce.mintDsc(amountToMint);
         vm.stopPrank();
         (uint256 amountMinted,)=dsce.getAccountInformation(USER);
         assertEq(amountMinted, amountToMint);
    }

/////////////////////////////
    // Redeem Tests //
    /////////////////////////////

    function testRedeemCollateralForDsc()public depositedCollateral{
         vm.startPrank(USER);
         dsce.mintDsc(amountToMint);
         dsc.approve(address(dsce), amountToMint);
         (uint256 amountMinted,)=dsce.getAccountInformation(USER);
         dsce.redeemCollateralForDsc(weth,AMOUNT_COLLATERAL/2,amountMinted/2);
        
         vm.stopPrank();
         (uint256 amountBurn,)=dsce.getAccountInformation(USER);
         assertEq(50 ether, amountBurn);

        
    }
    function testdepositCollaterAndMintDsc () public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollaterAndMintDsc(weth, AMOUNT_COLLATERAL,amountToMint);
        vm.stopPrank();
        (uint256 amountMinted,)=dsce.getAccountInformation(USER);
        assertEq(amountMinted,amountToMint);
    }
     function testLiquidate() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsc.approve(address(dsce), amountToMint);
        dsce.depositCollaterAndMintDsc(weth, AMOUNT_COLLATERAL,amountToMint);
         ( uint256 Db,uint256 before)=dsce.getAccountInformation(USER);
         console.log("before",before);
        vm.stopPrank();


        vm.startPrank(USER2);
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(int256(New_ETH_USD_PRICE));
        ERC20Mock(weth).approve(address(dsce), 2*AMOUNT_COLLATERAL);
        dsce.depositCollaterAndMintDsc(weth, 2*AMOUNT_COLLATERAL,amountToMint);
        
        ( uint256 Da,uint256 user2mit)=dsce.getAccountInformation(USER);
        
        dsc.approve(address(dsce),amountToMint);
        dsce.liquidate(weth,USER,amountToMint);
        ( ,uint256 afterliq)=dsce.getAccountInformation(USER);
        console.log("aftere",afterliq);
        // assertEq(afterliq, 0);
        vm.stopPrank();
}


}
