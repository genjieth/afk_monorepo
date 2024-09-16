import '../../../applyGlobalPolyfills';

import { webln } from '@getalby/sdk';
import { useAuth, useCashu, useCashuStore, useNostrContext, useSendZap } from 'afk_nostr_sdk';
import * as Clipboard from 'expo-clipboard';
import React, { SetStateAction, useEffect, useState } from 'react';
import { FlatList, Platform, Pressable, RefreshControl, SafeAreaView, ScrollView, TouchableOpacity, View } from 'react-native';
import { ActivityIndicator, Modal, Text, TextInput } from 'react-native';
import { WebView } from 'react-native-webview';
import PolyfillCrypto from 'react-native-webview-crypto';

import { Button, Divider, IconButton, Input } from '../../components';
import { useStyles, useTheme } from '../../hooks';
import { useDialog, useToast } from '../../hooks/modals';
import stylesheet from './styles';
import { CashuMint, MintQuoteResponse, MintQuoteState } from '@cashu/cashu-ts';
import { CopyIconStack } from '../../assets/icons';
import { canUseBiometricAuthentication } from 'expo-secure-store';
import { retrieveAndDecryptCashuMnemonic, retrievePassword, storeCashuMnemonic } from '../../utils/storage';
import { SelectedTab, TABS_CASHU } from '../../types/tab';
import { getInvoices } from '../../utils/storage_cashu';
import { ICashuInvoice } from '../../types/wallet';


export const InvoicesListCashu = () => {

  const { wallet, connectCashMint,
    connectCashWallet,
    requestMintQuote,
    generateMnemonic,
    derivedSeedFromMnenomicAndSaved,
    getKeySets,
    getKeys,
    checkMeltQuote,
    checkMintQuote,
    checkProofSpent

  } = useCashu()
  const { ndkCashuWallet, ndkWallet } = useNostrContext()

  const [mintUrl, setMintUrl] = useState<string | undefined>("https://mint.minibits.cash/Bitcoin")
  const [mint, setMint] = useState<CashuMint | undefined>(mintUrl ? new CashuMint(mintUrl) : undefined)

  const { isSeedCashuStorage, setIsSeedCashuStorage } = useCashuStore()
  const [invoices, setInvoices] = useState<ICashuInvoice[] | undefined>([])

  useEffect(() => {


    (async () => {

      const invoicesLocal = await getInvoices()


      if (invoicesLocal) {
        const invoices: ICashuInvoice[] = JSON.parse(invoicesLocal)
        console.log("invoices", invoices)
        setInvoices(invoices)


      }
    })();



    (async () => {
      const biometrySupported = Platform.OS !== 'web' && canUseBiometricAuthentication?.();

      if (biometrySupported) {
        const password = await retrievePassword()
        if (!password) return;
        const storeSeed = await retrieveAndDecryptCashuMnemonic(password);

        if (storeSeed) setHasSeedCashu(true)

        if (isSeedCashuStorage) setHasSeedCashu(true)
      }
    })();

    (async () => {

      // const keysSet = await getKeySets()
      // const keys = await getKeys()
      // console.log("keysSet", keysSet)
      // console.log("keys", keys)

      // const mintBalances = await ndkCashuWallet?.mintBalances;

      // console.log("mintBalances", mintBalances)

      // const availableTokens = await ndkCashuWallet?.availableTokens;
      // console.log("availableTokens", availableTokens)

      // const wallets = await ndkWallet?.wallets;

      // console.log("wallets", wallets)
      // const balance = await ndkCashuWallet?.balance;

      // console.log("balance", balance)

      // if (mint) {
      //   const mintBalance = await ndkCashuWallet?.mintBalance(mint?.mintUrl);
      //   console.log("mintBalance", mintBalance)

      // }




    })();
  }, []);


  const styles = useStyles(stylesheet);


  const [quote, setQuote] = useState<MintQuoteResponse | undefined>()
  const [mintsUrls, setMintUrls] = useState<string[]>(["https://mint.minibits.cash/Bitcoin"])
  const [isInvoiceModalVisible, setIsInvoiceModalVisible] = useState(false);
  const [isZapModalVisible, setIsZapModalVisible] = useState(false);
  const [hasSeedCashu, setHasSeedCashu] = useState(false);

  const [isLoading, setIsLoading] = useState(false);
  const [zapAmount, setZapAmount] = useState('');
  const [zapRecipient, setZapRecipient] = useState('');
  const [connectionStatus, setConnectionStatus] = useState('disconnected');
  const [connectionData, setConnectionData] = useState<any>(null);

  const { theme } = useTheme();
  const [newSeed, setNewSeed] = useState<string | undefined>()

  const { showDialog, hideDialog } = useDialog()

  const { showToast } = useToast()

  const [selectedTab, setSelectedTab] = useState<SelectedTab | undefined>(SelectedTab.LIGHTNING_NETWORK_WALLET);


  const handleVerifyQuote = async (quote?: string) => {

    if (!quote) {
      return showToast({ title: "Use a valid quote string", type: "info" })
    }
    const check = await checkMintQuote(quote)
    console.log("check", check)

    if (check) {

      if (check?.state == MintQuoteState.PAID) {
        return showToast({
          title: "Quote paid",
          type: "success"
        })
      }
      else if (check?.state == MintQuoteState.UNPAID) {
        return showToast({
          title: "Quote unpaid",
          type: "info"
        })
      }
      else if (check?.state == MintQuoteState.ISSUED) {
        return showToast({
          title: "Quote issued",
          type: "info"
        })
      }

    }
    return showToast({
      title: "Verify coming soon",
      type: "error"
    })
  }

  const handleCopy = async (bolt11?: string) => {
    if (!bolt11) return;
    await Clipboard.setStringAsync(bolt11);

    showToast({
      title: "Your invoice is copied",
      type: "info"
    })
  };

  return (
    // <SafeAreaView style={styles.safeArea}>
    <ScrollView contentContainerStyle={styles.scrollView}>
      <View style={styles.container}>

        <FlatList
          ItemSeparatorComponent={() => <Divider></Divider>}
          data={invoices?.flat().reverse()}
          contentContainerStyle={styles.flatListContent}

          keyExtractor={(item, i) => item?.bolt11 ?? i?.toString()}
          renderItem={({ item }) => {
            const date = item?.date && new Date(item?.date)?.toISOString()
            return (<View style={styles.card}>
              <View>

                <Input
                  value={item?.bolt11}
                  editable={false}
                  right={
                    <TouchableOpacity
                      onPress={() => handleCopy(item?.bolt11)}
                      style={{
                        marginRight: 10,
                      }}
                    >
                      <CopyIconStack color={theme.colors.primary} />
                    </TouchableOpacity>
                  }
                />
                <Text>Amount: {item?.amount}</Text>
                <Text>Mint: {item?.mint}</Text>
                <Text>Status: {item?.state}</Text>
                {date &&
                  <Text>Date: {date}</Text>}

              </View>


              <View>
                <Button
                  onPress={() => handleVerifyQuote(item?.quote)}
                >Verify</Button>

              </View>

            </View>)
          }}
        />



      </View>
    </ScrollView>
    // </SafeAreaView >
  );
};
