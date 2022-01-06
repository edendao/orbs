import "@nomiclabs/hardhat-ethers"

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { expect } from "chai"
import { writeFile } from "fs/promises"
import { deployments, ethers, network } from "hardhat"

import { OrbNFT } from "../typechain"

function parseZorb(zorb: string) {
  const zorbJSONStr = Buffer.from(
    zorb.substring("data:application/json;base64,".length),
    "base64",
  ).toString("utf-8")
  const zorbJSON = JSON.parse(zorbJSONStr)
  return zorbJSON
}

function makeInline(zorb: string) {
  return Buffer.from(zorb.substring(zorb.indexOf(",")), "base64").toString(
    "utf-8",
  )
}

describe("OrbNFT", () => {
  let signer: SignerWithAddress
  let signerAddress: string
  let signer2: SignerWithAddress
  let signer2Address: string
  let signer3: SignerWithAddress
  let signer3Address: string

  let childNft: OrbNFT

  beforeEach(async () => {
    const { OrbNFT } = await deployments.fixture(["OrbNFT"])

    childNft = (await ethers.getContractAt("OrbNFT", OrbNFT.address)) as OrbNFT
    ;[signer, signer2, signer3] = await ethers.getSigners()
    ;[signerAddress, signer2Address, signer3Address] = await Promise.all([
      signer.getAddress(),
      signer2.getAddress(),
      signer3.getAddress(),
    ])
  })

  it("hides from marketplace transfers", async () => {
    await childNft.mintTo(signerAddress)
    await childNft.setKnownMarketplaces([signer2Address], true)
    await childNft.transferFrom(signerAddress, signer2Address, 1)
    // shows old
    expect(await childNft.getOrbRenderAddress(1)).to.be.equal(signerAddress)
    await childNft
      .connect(signer2)
      .transferFrom(signer2Address, signer3Address, 1)
    expect(await childNft.getOrbRenderAddress(1)).to.be.equal(signer3Address)
  })

  it("renders", async () => {
    const signers = await ethers.getSigners()
    await network.provider.send("evm_setNextBlockTimestamp", [1641013200])
    await network.provider.send("evm_mine")
    const zorbs = []
    const signerAddresses: string[] = []
    for (let i = 0; i < 20; i++) {
      await childNft.connect(signers[i]).mint()
      const zorb = await childNft.tokenURI(i + 1)
      zorbs.push(parseZorb(zorb).image)
      signerAddresses.push(await signers[i].getAddress())
    }
    await writeFile(
      "./out/zorb.html",
      zorbs
        .map(
          (zorb, indx) =>
            `<div>${signerAddresses[indx]}${makeInline(zorb).replace(
              /gzr/g,
              `gzr${indx}`,
            )}<zora-zorb address="${signerAddresses[indx]}"></zora-zorb></div>`,
        )
        .join("\n") + `<script src="./zorb-web-component.umd.js"></script>`,
    )
  })
})
