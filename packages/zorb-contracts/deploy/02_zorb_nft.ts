module.exports = async ({ getNamedAccounts, deployments }: any) => {
  const { deploy } = deployments
  const { deployer, sharedNFTLogic } = await getNamedAccounts()

  const sharedNFTLogicAddress =
    sharedNFTLogic ?? (await deployments.get("TestSharedNFTLogic")).address

  await deploy("OrbNFT", {
    from: deployer,
    args: [sharedNFTLogicAddress],
    log: true,
  })
}

module.exports.tags = ["OrbNFT"]
module.exports.dependencies = ["TestSharedNFTLogic"]
