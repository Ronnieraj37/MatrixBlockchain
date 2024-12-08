# counter 
source .env && forge script forgeScripts/counter/DeployGateway.s.sol:DeployGateway --rpc-url $OFF_CHAIN_VM_RPC --private-key $PRIVATE_KEY --skip-simulation --broadcast
source .env && forge script forgeScripts/counter/DeployContracts.s.sol:DeployContracts --rpc-url $OFF_CHAIN_VM_RPC --private-key $PRIVATE_KEY --skip-simulation --broadcast
source .env && forge script forgeScripts/counter/Increment.s.sol:Increment --rpc-url $OFF_CHAIN_VM_RPC --private-key $PRIVATE_KEY --skip-simulation --broadcast

# super token
source .env && forge script forgeScripts/super-token/DeployGateway.s.sol:DeployGateway --rpc-url $OFF_CHAIN_VM_RPC --private-key $PRIVATE_KEY --skip-simulation --broadcast
source .env && forge script forgeScripts/super-token/DeployContracts.s.sol:DeployContracts --rpc-url $OFF_CHAIN_VM_RPC --private-key $PRIVATE_KEY --skip-simulation --broadcast
source .env && forge script forgeScripts/super-token/Bridge.s.sol:Bridge --rpc-url $OFF_CHAIN_VM_RPC --private-key $PRIVATE_KEY --skip-simulation --broadcast

# deposit fees
source .env && forge script forgeScripts/depositFees.s.sol:DepositFees --rpc-url $ARBITRUM_SEPOLIA_RPC --private-key $SPONSOR_KEY  --broadcast
