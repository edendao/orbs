import { ethers } from "ethers"

import { NETWORK_ID, RPC_URL, ZORB_CONTRACT } from "./env-vars"

const Contract = new ethers.Contract(ZORB_CONTRACT, [
  "function ownerOf(uint256 tokenId) view returns (address)",
  "function orbForAddress(address user) view returns (string)",
  "function getOrbRenderAddress(uint256 tokenId) view returns (address)",
])

export async function getTokenInfo(tokenId: string) {
  const provider = new ethers.providers.JsonRpcBatchProvider(
    RPC_URL,
    parseInt(NETWORK_ID || "4"),
  )
  const connectedContract = Contract.connect(provider)
  const ownerAddress = await connectedContract.ownerOf(tokenId)
  const renderAddress = await connectedContract.getOrbRenderAddress(tokenId)
  const zorbImage = await connectedContract.orbForAddress(renderAddress)
  return { ownerAddress, zorbImage }
}
