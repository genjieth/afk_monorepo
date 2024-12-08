#[cfg(test)]
mod exponential_tests {
    use afk_launchpad::launchpad::calcul::exponential::{
        get_coin_amount_by_quote_amount_exponential, calculate_initial_price, dynamic_scale_factor
    };
    use afk_launchpad::launchpad::calcul::linear::{get_coin_amount, get_meme_amount};
    use afk_launchpad::types::launchpad_types::{
        TokenLaunch, BondingType, TokenQuoteBuyCoin, LiquidityType
    };
    use starknet::{ContractAddress};

    fn OWNER() -> ContractAddress {
        'owner'.try_into().unwrap()
    }
    fn CREATOR() -> ContractAddress {
        'creator'.try_into().unwrap()
    }

    const THRESHOLD_LIQUIDITY: u256 = 10;
    const GROWTH_FACTOR: u256 = 100_000_u256;

    const SCALE_FACTOR: u256 = 100_000_000_000_000_000_000_u256;

    const DEFAULT_SUPPLY: u256 = 100_000_000_u256;
    const DEFAULT_LIQUIDITY_RATIO: u256 = 5_u256;


    fn get_token_launch(
        total_supply: u256, threshold_liquidity: u256, available_supply: u256
    ) -> TokenLaunch {
        let token_quote_buy = TokenQuoteBuyCoin {
            token_address: '123'.try_into().unwrap(),
            starting_price: 0_u256,
            price: 0_u256,
            step_increase_linear: 0_u256,
            is_enable: true //TODO
        };
        let mut available_supply = 80_000_000;

        let dynamic_scale_factor = dynamic_scale_factor(
            SCALE_FACTOR, available_supply, threshold_liquidity
        );

        // let starting_price= calculate_initial_price(THRESHOLD_LIQUIDITY,available_supply,
        // GROWTH_FACTOR);
        let starting_price = calculate_initial_price(
            THRESHOLD_LIQUIDITY, available_supply, GROWTH_FACTOR, dynamic_scale_factor
        );
        println!("starting_price {:?}", starting_price);

        let token_launch = TokenLaunch {
            owner: OWNER(),
            creator: CREATOR(),
            token_address: '123'.try_into().unwrap(),
            price: 0_u256, // Last price of the token.
            available_supply, // Available to buy
            initial_pool_supply: 0_u256, // Liquidity token to add in the DEX
            initial_available_supply: 0_u256, // Init available to buy
            total_supply, // Total supply to buy
            bonding_curve_type: BondingType::Linear,
            created_at: 0_u64,
            token_quote: token_quote_buy, // Token launched
            liquidity_raised: 0_u256, // Amount of quote raised. Need to be below threshold
            total_token_holded: 0_u256, // Number of token holded and buy
            is_liquidity_launch: true, // Liquidity launch through Ekubo or Unrug
            slope: 0_u256,
            threshold_liquidity, // Amount of maximal quote token to paid the coin launched
            liquidity_type: Option::None,
            // starting_price: 0_u256,
            starting_price: starting_price,
            protocol_fee_percent: 0_u256,
            creator_fee_percent: 0_u256,
        };

        token_launch
    }

    // #[test]
    // fn test_get_meme_amount_with_for_threshold() {
    //     let mut token_launch = get_token_launch(
    //         DEFAULT_SUPPLY, THRESHOLD_LIQUIDITY, DEFAULT_SUPPLY / DEFAULT_LIQUIDITY_RATIO
    //     );
    //     let amounts = array![5, 5]; // Quote tokens used for each transaction
    //     let mut amount_outs = array![];

    //     for amount_in in amounts {
    //         println!("amount_in {:?}", amount_in);

    //         // Calculate the memecoin amount out
    //         let amount_out = get_meme_amount(token_launch.clone(), amount_in);
    //         println!("amount_out {:?}", amount_out);

    //         // Assert amount_out does not exceed available supply
    //         assert!(
    //             amount_out <= token_launch.available_supply, "Amount sold exceeds available
    //             supply"
    //         );

    //         // Update available supply
    //         token_launch.available_supply -= amount_out;
    //         println!("token_launch.available_supply: {}", token_launch.available_supply);

    //         // Store the result for verification
    //         amount_outs.append(amount_out);
    //         println!("looping ------------------------------------------");
    //     }

    //     // Final assertions
    //     println!("amount 1: {}", amount_outs.at(0));
    //     println!("amount 2: {}", amount_outs.at(1));
    //     assert!(token_launch.available_supply >= 0, "Available supply cannot be negative");
    // }

    
    #[test]
    fn test_get_meme_amount_with_5_steps() {
        let mut available_supply = 80_000_000;
        // let mut token_launch = get_token_launch(
        //     DEFAULT_SUPPLY, THRESHOLD_LIQUIDITY, DEFAULT_SUPPLY / DEFAULT_LIQUIDITY_RATIO
        // );
        let mut token_launch = get_token_launch(
            DEFAULT_SUPPLY, THRESHOLD_LIQUIDITY, available_supply
        );

        let dynamic_scale_factor = dynamic_scale_factor(
            SCALE_FACTOR, available_supply, THRESHOLD_LIQUIDITY
        );
        let amounts = array![1, 1,1,1,6];
        let mut amount_outs = array![];
        for amount_in in amounts {
            println!("amount_in {:?}", amount_in);

            let amount_out = get_coin_amount_by_quote_amount_exponential(
                token_launch, amount_in, false, dynamic_scale_factor
            );
            println!("amount_out {:?}", amount_out);

            assert!(amount_out <= token_launch.available_supply, "too much");

            token_launch.available_supply -= amount_out;
            // token_launch.available_supply -= amount_out - token_launch.available_supply;
            println!("token_launch.available_supply: {}", token_launch.available_supply);
            amount_outs.append(amount_out);
            println!("looping {:?}------------------------------------------", amount_in);
        };

        println!("amount 1 : {}", amount_outs.at(0));
        println!("amount 2 : {}", amount_outs.at(1));
        // println!("amount 3 : {}", amount_outs.at(2));
    // println!("amount 4 : {}", amount_outs.at(3));
    }


    #[test]
    fn test_get_meme_amount_with_two_buy_for_threshold() {
        let mut available_supply = 80_000_000;
        // let mut token_launch = get_token_launch(
        //     DEFAULT_SUPPLY, THRESHOLD_LIQUIDITY, DEFAULT_SUPPLY / DEFAULT_LIQUIDITY_RATIO
        // );
        let mut token_launch = get_token_launch(
            DEFAULT_SUPPLY, THRESHOLD_LIQUIDITY, available_supply
        );

        let dynamic_scale_factor = dynamic_scale_factor(
            SCALE_FACTOR, available_supply, THRESHOLD_LIQUIDITY
        );

        // let amounts = array![20_000_000, 20_000_000, 20_000_000, 19_000_000];
        let amounts_received = array![20_000_000, 20_000_000, 20_000_000, 19_000_000];
        // let amounts = array![5, 5];
        let amounts = array![5, 5];
        let mut amount_outs = array![];

        for amount_in in amounts {
            println!("amount_in {:?}", amount_in);

            let amount_out = get_coin_amount_by_quote_amount_exponential(
                token_launch, amount_in, false, dynamic_scale_factor
            );
            println!("amount_out {:?}", amount_out);

            assert!(amount_out <= token_launch.available_supply, "too much");

            token_launch.available_supply -= amount_out;
            // token_launch.available_supply -= amount_out - token_launch.available_supply;
            println!("token_launch.available_supply: {}", token_launch.available_supply);
            amount_outs.append(amount_out);
            println!("looping ------------------------------------------");
        };

        println!("amount 1 : {}", amount_outs.at(0));
        println!("amount 2 : {}", amount_outs.at(1));
        // println!("amount 3 : {}", amount_outs.at(2));
    // println!("amount 4 : {}", amount_outs.at(3));
    }

    #[test]
    fn test_get_meme_amount_with_two_buy_for_threshold_low_supply() {
        let mut available_supply = 80_000_u256;
        // let mut token_launch = get_token_launch(
        //     DEFAULT_SUPPLY, THRESHOLD_LIQUIDITY, DEFAULT_SUPPLY / DEFAULT_LIQUIDITY_RATIO
        // );
        let mut token_launch = get_token_launch(
            100_000_u256, THRESHOLD_LIQUIDITY, available_supply
        );
        let dynamic_scale_factor = dynamic_scale_factor(
            SCALE_FACTOR, available_supply, THRESHOLD_LIQUIDITY
        );

        // let amounts = array![20_000_000, 20_000_000, 20_000_000, 19_000_000];
        let amounts_received = array![20_000_000, 20_000_000, 20_000_000, 19_000_000];
        let amounts = array![5, 5];
        let mut amount_outs = array![];

        for amount_in in amounts {
            println!("amount_in {:?}", amount_in);

            let amount_out = get_coin_amount_by_quote_amount_exponential(
                token_launch, amount_in, false, dynamic_scale_factor
            );
            println!("amount_out {:?}", amount_out);

            assert!(amount_out <= token_launch.available_supply, "too much");

            token_launch.available_supply -= amount_out;
            // token_launch.available_supply -= amount_out - token_launch.available_supply;
            println!("token_launch.available_supply: {}", token_launch.available_supply);
            amount_outs.append(amount_out);
            println!("looping ------------------------------------------");
        };

        println!("amount 1 : {}", amount_outs.at(0));
        println!("amount 2 : {}", amount_outs.at(1));
        // println!("amount 3 : {}", amount_outs.at(2));
    // println!("amount 4 : {}", amount_outs.at(3));
    }
    //     #[test]
// fn test_scale_factor_based_on_threshold_and_supply() {
//     // Base scale factor
//     let base_scale_factor = 1000000000000; // 10^12

    //     // Test case 1: Small ratio
//     let threshold_liquidity = 10;
//     let sellable_supply = 1000000;
//     let scaled_factor = scale_factor_based_on_threshold_and_supply(
//         threshold_liquidity, sellable_supply, base_scale_factor
//     );
//     assert scaled_factor == base_scale_factor * 10, "Failed for small ratio";

    //     // Test case 2: Large ratio
//     let threshold_liquidity = 1000000;
//     let sellable_supply = 10;
//     let scaled_factor = scale_factor_based_on_threshold_and_supply(
//         threshold_liquidity, sellable_supply, base_scale_factor
//     );
//     assert scaled_factor == base_scale_factor / 10, "Failed for large ratio";

    //     // Test case 3: Default scaling
//     let threshold_liquidity = 1000;
//     let sellable_supply = 1000;
//     let scaled_factor = scale_factor_based_on_threshold_and_supply(
//         threshold_liquidity, sellable_supply, base_scale_factor
//     );
//     assert scaled_factor == base_scale_factor, "Failed for default scaling";

    //     return ();
// }

    // #[test]
// fn test_get_meme_amount_with_diminishing_supply() {
//     let mut available_supply = 80_000_000;
//     let mut token_launch = get_token_launch(100_000_000, THRESHOLD_LIQUIDITY,
//     available_supply);
//     // let amounts = array![20_000_000, 20_000_000, 20_000_000, 19_000_000];
//     let amounts_received = array![20_000_000, 20_000_000, 20_000_000, 19_000_000];
//     let amounts = array![1, 20_000_000, 20_000_000, 19_000_000];

    //     let mut amount_outs = array![];

    //     for amount_in in amounts {
//         let amount_out = get_meme_amount(token_launch, amount_in);

    //         token_launch.available_supply -= 20_000_000;
//         println!("token_launch.available_supply: {}",  token_launch.available_supply);
//         amount_outs.append(amount_out);
//         println!("looping ------------------------------------------",);
//     };

    //     println!("amount 1 : {}", amount_outs.at(0));
//     println!("amount 2 : {}", amount_outs.at(1));
//     println!("amount 3 : {}", amount_outs.at(2));
//     println!("amount 4 : {}", amount_outs.at(3));
// }

    // #[test]
// fn test_get_meme_amount_fixed_supply() {
//     let mut available_supply = 80_000_000;
//     let mut token_launch = get_token_launch(100_000_000, THRESHOLD_LIQUIDITY,
//     available_supply);
//     let amounts = array![10_000_000, 20_000_000, 40_000_000, 60_000_000, 79_000_000];

    //     let mut amount_outs = array![];

    //     for amount_in in amounts {
//         let amount_out = get_meme_amount(token_launch, amount_in);
//         amount_outs.append(amount_out);

    //         println!("looping ------------------------------------------",);
//     };

    //     println!("amount 1 : {}", amount_outs.at(0));
//     println!("amount 2 : {}", amount_outs.at(1));
//     println!("amount 3 : {}", amount_outs.at(2));
//     println!("amount 4 : {}", amount_outs.at(3));
//     println!("amount 4 : {}", amount_outs.at(4));
// }
}