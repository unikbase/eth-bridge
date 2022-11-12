const provider = new ethers.Web3provider(window.ethereum); 
await provider.send("eth_requestAccounts",[]); 
const signer = provider.getSigner();
const address = signer.getAddress(); 

const LiquiChainToEthereum = async (TokenId)=>{
    const BridgecontractAddress = ""; 
    const BridgecontractABI = ""; 
    const contract2 = new ethers.contract(BridgecontractABI,BridgecontractAddress,provider); 
    const {chainId} = provider.getNetwork(); 
    const LiquidId = "" // provide the liquid chain id in decimals 
    if(chainId != LiquidId){
    window.ethereum.request({
        method: "wallet_addEthereumChain",
        params: [{
            chainId: "0x89", // provide the Liquichain chain id in hexadecimal way 
            }
        ]
    });
}else{
    await  contract2.connect(signer).BridgeToken(TokenId); 
    await contract2.on("BridgeNFT",(owner,id,uri,event)=>{
        MintOnEthereum(owner,id,uri); 
        console.log(event); 
    })
}
}
const MintOnEthereum = async (owner,id,uri)=>{
    const ETHNFTcontractABI = ""; 
    const ETHNFTcontractAddress = "" ; 
    const contract = new ethers.contract(ETHNFTcontractABI,ETHNFTcontractAddress,provider);
    window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{
            chainId: "0x1",
        }]
    });
    const privateKey = ""; // place your privatekey 
    const _signer = new ethers.Wallet(privateKey); 
    const to = ""; // provide some random address 
    const amount = 999
    const message = "Hello"
    const nonce = 123

    const hash = await contract.getMessageHash(to, amount, message, nonce)
    const sig = await _signer.signMessage(ethers.utils.arrayify(hash))

    const ethHash = await contract.getEthSignedMessageHash(hash)

    //console.log("signer", signer.address)
    //console.log("recovered signer", await contract.recoverSigner(ethHash, sig))
    await contract.connect(signer).mint(owner,id,signer.address, to, amount, message, nonce, sig); 
    await contract.connect(signer).setTokenURI(id,uri); 
}
const ethereumToLiquichain = async (owner,id)=>{
    const ETHNFTcontractABI = ""; 
    const ETHNFTcontractAddress = "" ; 
    const contract = new ethers.contract(ETHNFTcontractABI,ETHNFTcontractAddress,provider);
    const {chainId} = provider.getNetwork(); 
    if(chainId != 1){
        window.ethereum.request({
            method: "wallet_switchEthereumChain",
            params: [{
                chainId: "0x1",
            }]
        });
    }else{
        await contract.connect(signer).Burn(owner,id); 
        WithdrawTheNFT(owner,id); 
    }
}
const WithdrawTheNFT = async (owner,id) =>{
    const BridgecontractAddress = ""; 
    const BridgecontractABI = ""; 
    const contract2 = new ethers.contract(BridgecontractABI,BridgecontractAddress,provider); 
    const {chainId} = provider.getNetwork(); 
    const LiquidId = "" // provide the liquid chain id in decimals 
    if(chainId != LiquidId){
    window.ethereum.request({
        method: "wallet_addEthereumChain",
        params: [{
            chainId: "0x89", // provide the Liquichain chain id in hexadecimal way 
            }
        ]
    });
}
else{
    await contract2.connect(signer).withDrawNFT(owner,id); 
}
}
