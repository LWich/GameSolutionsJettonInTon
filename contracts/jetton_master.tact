import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./jetton_wallet";


contract JettonMaster with Deployable, Ownable {
    id: Int as uint32;
    totalSupply: Int;
    mintable: Bool;
    owner: Address;
    content: Cell?;

    init(id: Int) {
        self.id = id;

        self.owner = sender();
        self.totalSupply = ton("500");
        self.mintable = true;
    }

    receive(msg: TokenUpdateContent) {
        self.requireOwner();
        
        self.content = msg.content;
    }

    receive("stop mint") {
        self.requireOwner();

        self.mintable = false;
    }

    receive(msg: TokenBurnNotification) {        
        self.requireWallet(msg.owner);

        self.totalSupply = self.totalSupply - msg.amount;

        if (msg.responseAddress != null) {
            send(SendParameters{
                to: msg.responseAddress!!, 
                value: 0,
                bounce: false,
                mode: SendRemainingValue + SendIgnoreErrors,
                body: TokenExcesses{
                    queryId: msg.queryId
                }.toCell()
            });
        }
    }

    receive(msg: MintTokens) {
        self.requireOwner();
        self.requireMintable();

        self.totalSupply = self.totalSupply + msg.amount;

        let winit: StateInit = self.getJettonWalletInit(msg.to);
        let walletAddress: Address = contractAddress(winit);
        send(SendParameters{
            to: walletAddress, 
            value: 0, 
            bounce: false,
            mode: SendRemainingValue,
            body: TokenTransferInternal{ 
                amount: msg.amount,
                queryId: 0,
                from: myAddress(),
                responseAddress: msg.responseAddress,
                forwardTonAmount: 0,
                forwardPayload: emptySlice()
            }.toCell(),
            code: winit.code,
            data: winit.data
        });
    }

    get fun get_wallet_address(owner: Address): Address {
        let winit: StateInit = self.getJettonWalletInit(owner);
        return contractAddress(winit);
    }

    get fun get_jetton_data(): JettonData {
        let code: Cell = self.getJettonWalletInit(myAddress()).code;
        return JettonData{ 
            totalSupply: self.totalSupply, 
            mintable: self.mintable, 
            owner: self.owner, 
            content: self.content, 
            walletCode: code
        };
    }

    fun requireWallet(owner: Address) {
        let ctx: Context = context();
        let winit: StateInit = self.getJettonWalletInit(owner);
        require(contractAddress(winit) == ctx.sender, "Invalid sender");
    }

    fun requireMintable() {
        require(self.mintable, "It is not mintable");
    }

    get fun myAddress(): Address {
        return myAddress();
    }
    
    fun getJettonWalletInit(address: Address): StateInit {
        return initOf JettonWallet(myAddress(), address);
    }
}
