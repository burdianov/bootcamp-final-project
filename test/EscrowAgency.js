const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('EscrowAgency', function () {
  let escrowAgency;
  let agent, buyer, seller;

  const buyerName = 'John';
  const sellerName = 'Mike';
  const buyerEmail = 'john@gmail.com';
  const sellerEmail = 'mike@gmail.com';

  const addressZero = '0x0000000000000000000000000000000000000000';

  beforeEach(async function () {
    [agent, buyer, seller, account3, account4, account5] =
      await ethers.getSigners();

    const EscrowAgency = await ethers.getContractFactory('EscrowAgency');

    escrowAgency = await EscrowAgency.deploy();
    await escrowAgency.deployed();
  });

  it('should register buyer', async () => {
    await escrowAgency.connect(buyer).registerBuyer(buyerName, buyerEmail);

    expect(await escrowAgency.buyersCount()).to.equal(1);

    const buyerDetails = await escrowAgency.getBuyerDetails(buyer.address);

    expect(buyerDetails.name).to.equal(buyerName);
    expect(buyerDetails.email).to.equal(buyerEmail);
  });

  it('should register seller', async () => {
    await escrowAgency.connect(seller).registerSeller(sellerName, sellerEmail);

    expect(await escrowAgency.sellersCount()).to.equal(1);

    const sellerDetails = await escrowAgency.getSellerDetails(seller.address);

    expect(sellerDetails.name).to.equal(sellerName);
    expect(sellerDetails.email).to.equal(sellerEmail);
  });

  it('should initiate escrow', async () => {
    await escrowAgency.connect(buyer).registerBuyer(buyerName, buyerEmail);
    await escrowAgency.connect(seller).registerSeller(sellerName, sellerEmail);
    await escrowAgency.connect(buyer).initiateEscrow(seller.address, 111);

    const escrowDetails = await escrowAgency.getEscrowsBySeller(seller.address);

    expect(escrowDetails[0].id).to.equal(0);
    expect(escrowDetails[0].expiryTime).to.equal(111);
    expect(escrowDetails[0].state).to.equal(0);
  });

  it('should confirm delivery', async () => {
    await escrowAgency.connect(buyer).registerBuyer(buyerName, buyerEmail);
    await escrowAgency.connect(seller).registerSeller(sellerName, sellerEmail);
    await escrowAgency.connect(buyer).initiateEscrow(seller.address, 111);

    let escrowDetails = await escrowAgency.getEscrowsBySeller(seller.address);

    expect(escrowDetails[0].state).to.equal(0);

    await escrowAgency.connect(buyer).confirmDelivery(0);

    escrowDetails = await escrowAgency.getEscrowsBySeller(seller.address);

    expect(escrowDetails[0].state).to.equal(2);
  });
});
