npx hardhat run scripts/deploy/1.deploy.ts 
npx hardhat run scripts/deploy/2.roles.ts --no-compile
npx hardhat run scripts/deploy/3.upgradeManagers.ts --no-compile
npx hardhat run scripts/deploy/4.connect.ts --no-compile
export AWS_PROFILE=lldev && npx ts-node scripts/deploy/5.upload.ts --resolveJsonModule
npx hardhat run scripts/deploy/verify.ts --no-compile