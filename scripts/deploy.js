const hre = require('hardhat');

async function main() {
  const Escrow = await hre.ethers.getContractFactory('Escrow');
  const escrow = await Escrow.deploy('Hello, Hardhat!');

  await escrow.deployed();

  console.log('Escrow deployed to:', escrow.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
