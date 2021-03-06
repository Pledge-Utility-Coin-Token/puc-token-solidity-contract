//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./PancakeRouter.sol";
import "./Open-Zeppelin.sol";

contract Pledge01Up is
Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable, OwnableUpgradeable {

    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 1e15 * 10 ** uint256(DECIMALS);

    /////////////////////////////////////////////////////////////////////////////////////
    //
    //                      Borrows from ERC20Upgradeable 
    //
    // _transfer(...) and _afterTokenTransfer(...) are re-implemented on the bottom part.
    //
    /////////////////////////////////////////////////////////////////////////////////////

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal {
        __Context_init_unchained();
        __Ownable_init();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the bep20 token owner which is necessary for binding with bep2 token
     */
	function getOwner() public view returns (address) {
		return owner();
	}

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];

        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];

        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }



    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] = accountBalance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    /////////////////////////////////////////////////////////////////////////////////////
    //
    //                      Borrows from ERC20BurnableUpgradeable 
    //
    /////////////////////////////////////////////////////////////////////////////////////

    function __ERC20Burnable_init() internal {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    /////////////////////////////////////////////////////////////////////////////////////
    //
    //                      Borrows from ERC20PresetFixedSupplyUpgradeable 
    //
    /////////////////////////////////////////////////////////////////////////////////////

    function initialize(Beneficiaries memory beneficiaries) public virtual initializer {
        __Ownable_init();
        _setBeneficiaries(beneficiaries);
        __ERC20PresetFixedSupply_init("Pledge Utility Coin Token", "PUC", INITIAL_SUPPLY, owner());
    }
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    function __ERC20PresetFixedSupply_init(
        string memory __name,
        string memory __symbol,
        uint256 initialSupply,
        address owner
    ) internal initializer {
        __Context_init_unchained();
		__Ownable_init_unchained();
        __ERC20_init_unchained(__name, __symbol);
        __ERC20Burnable_init_unchained();
        __ERC20PresetFixedSupply_init_unchained(initialSupply, owner);
        __Pledge_init_unchained();
    }

    function __ERC20PresetFixedSupply_init_unchained(
        uint256 initialSupply,
        address owner
    ) internal initializer {
        _mint(owner, initialSupply);
    }


	///////////////////////////////////////////////////////////////////////////////////////////////
	//
	// The state data items of this contract are packed below, after those of the base contracts.
	// The items are tightly arranged for efficient packing into 32-bytes slots.
	// See https://docs.soliditylang.org/en/v0.8.9/internals/layout_in_storage.html for more.
	//
	// Do NOT make any changes to this packing when you upgrade this implementation.
	// See https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies for more.
	//
	//////////////////////////////////////////////////////////////////////////////////////////////

    uint256 public constant FEE_MAGNIFIER = 100000; // Five zeroes.
    uint256 public constant FEE_HUNDRED_PERCENT = FEE_MAGNIFIER * 100;

    uint256 public constant INITIAL_LOWER_MARKETING_FEE = 375;      // this/FEE_MAGNIFIER = 0.00375 or 0.375%
    uint256 public constant INITIAL_LOWER_CHARITY_FEE = 125;        // this/FEE_MAGNIFIER = 0.00125 or 0.125%
    uint256 public constant INITIAL_LOWER_LIQUIDITY_FEE = 375;      // this/FEE_MAGNIFIER = 0.00375 or 0.375%
    uint256 public constant INITIAL_LOWER_LOTTERY_FEE = 125;        // this/FEE_MAGNIFIER = 0.00125 or 0.125%

    uint256 public constant INITIAL_HIGHER_MARKETING_FEE = 1500;    // this/FEE_MAGNIFIER = 0.01500 or 1.500%
    uint256 public constant INITIAL_HIGHER_CHARITY_FEE = 500;       // this/FEE_MAGNIFIER = 0.00500 or 0.500%
    uint256 public constant INITIAL_HIGHER_LIQUIDITY_FEE = 1500;    // this/FEE_MAGNIFIER = 0.01500 or 1.500%
    uint256 public constant INITIAL_HIGHER_LOTTERY_FEE = 500;       // this/FEE_MAGNIFIER = 0.00500 or 0.500%
   
    uint256 public constant MAX_TRANSFER_AMOUNT = 1e13 * 10**uint256(DECIMALS);
    uint256 public constant LIQUIDITY_QUANTUM = 1e5 * 10**uint256(DECIMALS);
    uint256 public constant MIN_HODL_TIME_SECONDS  = 31556952; // A year spans 31556952 seconds.

	using SafeMath for uint256;

    event SwapAndLiquify(
        uint256 tokenSwapped,
        uint256 etherReceived,
        uint256 tokenLiquified,
        uint256 etherLiquified
    );

	struct Fees {
		uint256 marketing;
		uint256 charity;
		uint256 liquidity;
		uint256 lottery;
	}

	struct FeeBalances {
		uint256 marketing;
		uint256 charity;
		uint256 liquidity;
		uint256 lottery;
	}

	struct Beneficiaries {
		address marketing;
		address charity;
		address liquidity;
		address lottery;
	}

    event FreeFromFees(address user, bool free);
    event FreeFromTransferLimit(address user, bool free);
    event SetFees(Fees fees, bool lowerNotHigher);

    Fees public initialLowerFees;
    Fees public lowerFees;
    Fees public initialHigherFees;
    Fees public higherFees;

    Beneficiaries public beneficiaries;

    uint256 public maxTransferAmount;
    uint256 public minHoldTimeSec;

	IPancakeRouter02 public pancakeRouter;
	address public pancakePair;

    address public generalCharityAddress;
	mapping(address => bool) public isCharityAddress;
	mapping(address => address) public preferredCharityAddress;

    mapping(address => bool) public isFeeFree;
    mapping(address => bool) public isTransferLimitFree;
	mapping(address => uint) public lastTransferTime;

	///////////////////////////////////////////////////////////////////////////////////////////////
	//
	// The logic (operational code) of the implementation.
	// You can upgrade this part of the implementation freely: 
	// - add new state data itmes.
	// - override, add, or remove.
	// You cannot make changes to the above existing state data items.
	//
	//////////////////////////////////////////////////////////////////////////////////////////////

    function __Pledge_init() public {
        __Pledge_init_unchained();
    }


    function __Pledge_init_unchained() public {        
		initialLowerFees.marketing = INITIAL_LOWER_MARKETING_FEE;
		initialLowerFees.charity = INITIAL_LOWER_CHARITY_FEE;
		initialLowerFees.liquidity = INITIAL_LOWER_LIQUIDITY_FEE;
		initialLowerFees.lottery = INITIAL_LOWER_LOTTERY_FEE;

        lowerFees = initialLowerFees;
        _checkFees(lowerFees);
        emit SetFees(lowerFees, true);

        initialHigherFees.marketing = INITIAL_HIGHER_MARKETING_FEE;
		initialHigherFees.charity = INITIAL_HIGHER_CHARITY_FEE;
		initialHigherFees.liquidity = INITIAL_HIGHER_LIQUIDITY_FEE;
		initialHigherFees.lottery = INITIAL_HIGHER_LOTTERY_FEE;

        higherFees = initialHigherFees;
        _checkFees(higherFees);
        emit SetFees(higherFees, false);

		maxTransferAmount = MAX_TRANSFER_AMOUNT;
        minHoldTimeSec = MIN_HODL_TIME_SECONDS;

        generalCharityAddress = beneficiaries.charity;
        lastTransferTime[owner()] = block.timestamp;
    }

    function feeBalances() external view returns(FeeBalances memory balances) {
        balances.marketing = _balances[beneficiaries.marketing];
        balances.charity = _balances[beneficiaries.charity];
        balances.liquidity = _balances[beneficiaries.liquidity];
        balances.lottery = _balances[beneficiaries.lottery];
    }

    function _checkFees(Fees memory fees) internal pure returns(uint256 total) {
        require(fees.marketing <= FEE_HUNDRED_PERCENT, "Marketing fee out of range");
        require(fees.charity <= FEE_HUNDRED_PERCENT, "Charity fee out of range");
        require(fees.lottery <= FEE_HUNDRED_PERCENT, "Lottery fee out of range");
        require(fees.liquidity <= FEE_HUNDRED_PERCENT, "Liquidity fee out of range");
        total = fees.marketing + fees.charity + fees.lottery + fees.liquidity;
        require(total <= FEE_HUNDRED_PERCENT, "Total fee out of range");
    }

    function restoreFees(bool lowerNotHigher) virtual public onlyOwner {
        if(lowerNotHigher == true) {
            lowerFees = initialLowerFees;
            emit SetFees(lowerFees, lowerNotHigher);
        } else {
            higherFees = initialHigherFees;
            emit SetFees(higherFees, lowerNotHigher);
        }
    }

    function setMinHoldTimeSec( uint256 _minHoldTimeSec ) virtual external onlyOwner {
        minHoldTimeSec = _minHoldTimeSec;
    }

	function setMaxTransferAmount(uint256 _maxTransferAmount) virtual external onlyOwner {
		maxTransferAmount = _maxTransferAmount;
	}

	function setBeneficiaries(Beneficiaries memory _beneficiaries) virtual external onlyOwner {
        _setBeneficiaries(_beneficiaries);
	}

    function _setBeneficiaries(Beneficiaries memory _beneficiaries) internal virtual {
        _freeFromFees(beneficiaries.charity, false);
        _freeFromFees(beneficiaries.marketing, false);
        _freeFromFees(beneficiaries.lottery, false);
        _freeFromFees(beneficiaries.liquidity, false);

        beneficiaries = _beneficiaries;

        _freeFromFees(_beneficiaries.charity, true);
        _freeFromFees(_beneficiaries.marketing, true);
        _freeFromFees(_beneficiaries.lottery, true);
        _freeFromFees(_beneficiaries.liquidity, true);
	}

	function createLiquidityPool( address _routerAddress ) virtual external onlyOwner {
		IPancakeRouter02 _pancakeRouter = IPancakeRouter02(_routerAddress);
		pancakeRouter = _pancakeRouter;

        pancakePair = IPancakeFactory(_pancakeRouter.factory()).getPair(address(this), _pancakeRouter.WETH());

        if(pancakePair == address(0)) {
    		pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        }
    }   
   
    function setFees(Fees memory fees, bool lowerNotHigher) virtual external onlyOwner {
        _checkFees(fees);

        if(lowerNotHigher) {
            lowerFees = fees;
            emit SetFees(lowerFees, lowerNotHigher);
        } else {
            higherFees = fees;
            emit SetFees(higherFees, lowerNotHigher);
        }
    }

    function freeFromFees(address user, bool free) external virtual onlyOwner {
        _freeFromFees(user, free);
    }

    function _freeFromFees(address user, bool free) internal virtual {
        isFeeFree[user] = free;
        emit FreeFromFees(user, free);
    }

    function freeFromTransferLimit(address user, bool free) external virtual onlyOwner {
        _freeFromTransferLimit(user, free);
    }

    function _freeFromTransferLimit(address user, bool free) internal virtual {
        isTransferLimitFree[user] = free;
        emit FreeFromTransferLimit(user, free);
    }

    function setGeneralCharityAddress(address _charityAddress) virtual external onlyOwner {
        // Allow zero-address.
        if(generalCharityAddress != address(0)) isCharityAddress[generalCharityAddress] = false;
        generalCharityAddress = _charityAddress;
        if(_charityAddress != address(0)) isCharityAddress[_charityAddress] = true;
    }

	function addCharityAddress(address _charityAddress) virtual external onlyOwner {
        // Assumption: unique or no existence.
        _addCharityAddress(_charityAddress);
	}

	function _addCharityAddress(address _charityAddress) internal virtual {
        // Assumption: unique or no existence.
        require(_charityAddress != address(0), "Invalid charity address");
        isCharityAddress[_charityAddress] = true;
	}

	function removeCharityAddress(address _charityAddress) virtual external onlyOwner {
        _removeCharityAddress(_charityAddress);
	}

	function _removeCharityAddress(address _charityAddress) internal virtual {
        require(_charityAddress != address(0), "Invalid charity address");
        isCharityAddress[_charityAddress] = false;
	}

	function changeCharityAddress(address _oldCharityAddress, address _newCharityAddress) virtual external onlyOwner {
        _removeCharityAddress(_oldCharityAddress);
        _addCharityAddress(_newCharityAddress);
	}

	function preferCharityAddress (address _charityAddress) virtual external {
        if( _charityAddress != address(0) )
            require (isCharityAddress[_charityAddress], "Charity address not found");
            
        // Allow overriding. Allow zero-addres, which de-prefers.
		preferredCharityAddress[msg.sender] = _charityAddress;
	}

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        if( ! _isUnlimitedTransfer(sender, recipient) ) {
            require(amount <= maxTransferAmount, "Transfer exceeds limit");
        }

        _balances[sender] -= amount;

   		if(! _isFeeFreeTransfer(sender, recipient) ) {
            _settleCharityRelation(sender, recipient);

            amount -= _payFees(sender, amount);

            lastTransferTime[sender] = block.timestamp;
            lastTransferTime[recipient] = block.timestamp;
        }

        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _isUnlimitedTransfer(address sender, address recipient) internal view virtual returns (bool unlimited) {
        // Start from highly frequent occurences.
        unlimited = _isBidirUnlimitedAddress(sender)
            || _isBidirUnlimitedAddress(recipient)
            || (sender == owner() && recipient == pancakePair)
            || (sender == pancakePair && recipient == owner());
    }

    function _isBidirUnlimitedAddress(address _address) internal view virtual returns (bool unlimited) {
        unlimited = _address == beneficiaries.marketing
            || _address == beneficiaries.charity
            || _address == beneficiaries.liquidity
            || _address == beneficiaries.lottery
            || isCharityAddress[_address]
            || isTransferLimitFree[_address];
    }  

    function _isFeeFreeTransfer(address sender, address recipient) internal view virtual returns (bool feeFree) {
        // Start from highly frequent occurences.
        feeFree = _isBidirFeeFreeAddress(sender) 
            || _isBidirFeeFreeAddress(recipient)
            || (sender == owner() && recipient == pancakePair)    
            || (sender == pancakePair && recipient == owner());
    }

    function _isBidirFeeFreeAddress(address _address) internal view virtual returns (bool feeFree) {
        feeFree = isFeeFree[_address]
            || _address == beneficiaries.marketing
            || _address == beneficiaries.charity
            || _address == beneficiaries.liquidity
            || _address == beneficiaries.lottery;
    }

    function _settleCharityRelation(address sender, address recipient) internal virtual {
        // Transferring directly to a charity that is not yet preferred.
        if(isCharityAddress[recipient] == true && preferredCharityAddress[sender] == address(0)) {
            preferredCharityAddress[sender] = recipient;
            beneficiaries.charity = recipient;
        } else {
            // Determine which charity to pay charity fees to?
            beneficiaries.charity = generalCharityAddress;
            address preferred = preferredCharityAddress[sender];
            if( preferred != address(0) && isCharityAddress[preferred] ) {
                // isCharityAddress[preferred] is required because the owner can freely remove a charity address without knowing if its a holder's preferred charity.
                beneficiaries.charity = preferredCharityAddress[sender];
            }
            require(beneficiaries.charity != address(0), "Invalid charity");
        }
    }

    function _payFees(address sender, uint256 principal) internal virtual returns (uint256 totalCharge) {
        if(block.timestamp - lastTransferTime[sender] >= minHoldTimeSec) {
            totalCharge += _creditWithFees(sender, principal, lowerFees, beneficiaries);
        } else {
            totalCharge += _creditWithFees(sender, principal, higherFees, beneficiaries);
        }
	}


	function _creditWithFees(address sender, uint256 principal, Fees storage fees, Beneficiaries storage _beneficiaries) 
    virtual internal returns (uint256 total) {
        uint256 fee = principal.mul(fees.marketing).div(FEE_MAGNIFIER);
        _balances[_beneficiaries.marketing] += fee;
        emit Transfer(sender, _beneficiaries.marketing, fee);
        total += fee;

        fee = principal.mul(fees.charity).div(FEE_MAGNIFIER);
        _balances[_beneficiaries.charity] += fee;
        emit Transfer(sender, _beneficiaries.charity, fee);
        total += fee;

        fee = principal.mul(fees.lottery).div(FEE_MAGNIFIER);
        _balances[_beneficiaries.lottery] += fee;
        emit Transfer(sender, _beneficiaries.lottery, fee);
        total += fee;

        fee = principal.mul(fees.liquidity).div(FEE_MAGNIFIER);
        _balances[_beneficiaries.liquidity] += fee;
        emit Transfer(sender, _beneficiaries.liquidity, fee);
        total += fee;

		return total;
	}
}
