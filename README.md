
Command Line orders
-compile: 
npx hardhat compile
-deploy: 
npx hardhat run deploy scripts/deploy.js --network binanceTest
-verify: 
npx hardhat verify --network bsctestnet 0x224158C46D709A76300f0A43e671409129b7691A 0xA6DD74936b88739366065F7B3B5C95852bf57F2B --show-stack-traces
