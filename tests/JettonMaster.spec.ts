import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { JettonMaster } from '../wrappers/JettonMaster';
import { JettonWallet } from '../wrappers/JettonWallet';
import '@ton/test-utils';

describe('JettonMaster', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let jettonMaster: SandboxContract<JettonMaster>;
    beforeEach(async () => {
        blockchain = await Blockchain.create();

        jettonMaster = blockchain.openContract(await JettonMaster.fromInit(12911n));

        deployer = await blockchain.treasury('deployer');

        const deployResult = await jettonMaster.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: jettonMaster.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and jettonMaster are ready to use
    });

    it('should mint tokens', async () => {
        const user = await blockchain.treasury('user');
        const userAddress = await user.address;

        await jettonMaster.send(
            deployer.getSender(),
            {
                value: toNano("0.2")
            },
            {
                $$type: "MintTokens",
                to: userAddress,
                amount: toNano("100"),
                responseAddress: null
            }
        );

        const address = await jettonMaster.getGetWalletAddress(userAddress);
        const jettonWallet = blockchain.openContract(await JettonWallet.fromAddress(address))

        const data = await jettonWallet.getGetWalletData();

        expect(data.balance).toEqual(toNano("100"));
    });
});
