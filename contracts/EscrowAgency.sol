//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract EscrowAgency {
    enum State {
        AWAITING_DELIVERY,
        CANCELLED,
        DELIVERED,
        COMPLETE
    }

    struct Escrow {
        uint256 id;
        address seller;
        address buyer;
        uint256 amount;
        uint256 createdAt;
        uint256 expiryTime;
        State state;
    }

    struct Seller {
        address payable id;
        string name;
        string email;
    }

    struct Buyer {
        address id;
        string name;
        string email;
    }

    address public agent;

    mapping(address => Seller) public sellers;
    mapping(address => Buyer) public buyers;
    mapping(uint256 => Escrow) public escrows;
    mapping(address => uint256[]) public buyerEscrows;
    mapping(address => uint256[]) public sellerEscrows;

    uint256 public buyersCount;
    uint256 public sellersCount;
    uint256 public escrowsCount;

    event EscrowCreated(
        address seller,
        address buyer,
        uint256 amount,
        uint256 createdAt
    );

    event EscrowCancelled(
        address seller,
        address buyer,
        uint256 amount,
        uint256 createdAt,
        uint256 cancelledAt
    );

    event GoodsDelivered(
        address seller,
        address buyer,
        uint256 amount,
        uint256 time
    );

    modifier onlyAgent() {
        require(msg.sender == agent);
        _;
    }

    modifier onlyBuyer(uint256 escrowId) {
        require(
            msg.sender == escrows[escrowId].buyer,
            "Not the buyer of this escrow"
        );
        _;
    }

    modifier notCancelled(uint256 escrowId) {
        require(
            escrows[escrowId].state != State.CANCELLED,
            "The escrow is cancelled"
        );
        _;
    }

    constructor() {
        agent = msg.sender;
    }

    function registerBuyer(string calldata name, string calldata email)
        external
    {
        require(
            buyers[msg.sender].id == address(0),
            "A buyer with this address has already been registered"
        );
        buyers[msg.sender] = Buyer(msg.sender, name, email);
        buyersCount++;
    }

    function registerSeller(string calldata name, string calldata email)
        external
    {
        require(
            sellers[msg.sender].id == address(0),
            "A seller with this address has already been registered"
        );
        sellers[msg.sender] = Seller(payable(msg.sender), name, email);
        sellersCount++;
    }

    // the buyer initiates the escrow
    function initiateEscrow(address payable seller, uint256 expiryTime)
        external
        payable
    {
        address buyer = msg.sender;
        uint256 amount = msg.value;

        require(buyers[buyer].id != address(0), "Not a registered buyer");
        require(sellers[seller].id != address(0), "Not a registered seller");
        require(amount >= 0, "Escrow amount should be greater than zero");

        // apply 3% discount
        amount = (amount * 97) / 100;

        Escrow memory escrow = Escrow(
            escrowsCount,
            seller,
            buyer,
            amount,
            block.timestamp,
            expiryTime,
            State.AWAITING_DELIVERY
        );

        escrows[escrowsCount] = escrow;
        buyerEscrows[buyer].push(escrowsCount);
        sellerEscrows[seller].push(escrowsCount);

        escrowsCount++;

        emit EscrowCreated(seller, buyer, amount, block.timestamp);
    }

    // the buyer cancels the escrow
    function cancelEscrow(uint256 escrowId)
        external
        onlyBuyer(escrowId)
        notCancelled(escrowId)
    {
        require(
            escrows[escrowId].state == State.AWAITING_DELIVERY,
            "The goods / service have already been delivered"
        );

        escrows[escrowId].state = State.CANCELLED;
    }

    // the buyer confirms the delivery
    function confirmDelivery(uint256 escrowId)
        external
        onlyBuyer(escrowId)
        notCancelled(escrowId)
    {
        require(
            escrows[escrowId].state == State.AWAITING_DELIVERY,
            "The escrow has already been delivered"
        );

        escrows[escrowId].state = State.DELIVERED;
    }

    // the seller withdraws the funds
    function withdraw(uint256 escrowId) external notCancelled(escrowId) {
        require(
            escrows[escrowId].seller == msg.sender,
            "You are not the seller of this escrow"
        );
        require(
            escrows[escrowId].state == State.DELIVERED,
            "The delivery has not yet been confirmed"
        );

        payable(msg.sender).transfer(escrows[escrowId].amount);
        escrows[escrowId].state == State.COMPLETE;
    }

    function getEscrowsBySeller(address seller)
        external
        view
        returns (Escrow[] memory)
    {
        uint256 escrowsSellerCount = 0;
        uint256 i;
        uint256 j;

        for (i = 0; i < escrowsCount; i++) {
            if (escrows[i].seller == seller) {
                escrowsSellerCount++;
            }
        }

        Escrow[] memory memoryEscrows = new Escrow[](escrowsSellerCount);

        for (i = 0; i < escrowsCount; i++) {
            if (escrows[i].seller == seller) {
                memoryEscrows[j] = escrows[i];
                j++;
            }
        }

        return memoryEscrows;
    }

    function getEscrowsByBuyer(address buyer)
        external
        view
        returns (Escrow[] memory)
    {
        uint256 escrowsBuyerCount = 0;
        uint256 i;
        uint256 j;

        for (i = 0; i < escrowsCount; i++) {
            if (escrows[i].buyer == buyer) {
                escrowsBuyerCount++;
            }
        }

        Escrow[] memory memoryEscrows = new Escrow[](escrowsBuyerCount);

        for (i = 0; i < escrowsCount; i++) {
            if (escrows[i].buyer == buyer) {
                memoryEscrows[j] = escrows[i];
                j++;
            }
        }

        return memoryEscrows;
    }

    function getBuyerDetails(address buyer)
        external
        view
        returns (Buyer memory)
    {
        return buyers[buyer];
    }

    function getSellerDetails(address seller)
        external
        view
        returns (Seller memory)
    {
        return sellers[seller];
    }
}
