//
//  LMEncryptKit.m
//  LMMessageUI
//
//  Created by MoHuilin on 2017/9/22.
//  Copyright © 2017年 connect. All rights reserved.
//

#import "LMEncryptKit.h"
#ifdef __cplusplus
#if __cplusplus
extern "C"{
#include "bip39.h"
#include "ecies.h"
#include "pbkdf2.h"
}
#endif
#endif /* __cplusplus */

#include "key.h"
#include "base58.h"
#include <openssl/aes.h>
#include <openssl/rand.h>
#include <boost/algorithm/string.hpp>
#include <boost/assign/list_of.hpp>
#include "json_spirit_reader_template.h"

@implementation LMEncryptGcmData

@end

@implementation LMEncryptKit

+ (NSString *)creatConnectIMPrivkey{
    char privkey[256];
    CreateNewPrivKey_im(privkey);
    return [NSString stringWithFormat:@"%s", privkey];
}

+ (NSString *)connectIMPubkeyByPrikey:(NSString *)prikey {
    char pubkey[256];
    GetPubKeyFromPrivKey_im((char *) [prikey UTF8String], pubkey);
    return [NSString stringWithFormat:@"%s", pubkey];
}

/// 签名
+ (NSString *)signData:(NSString *)signData privkey:(NSString *)privkey {
    if (!privkey || !signData) {
        return nil;
    }
    char *privkey_ = (char *) [privkey UTF8String];
    char *hashstr = (char *) [signData UTF8String];
    char signStr[256];
    int result = SignHash_im(privkey_, hashstr, signStr);
    if (result == 0) {
        return [NSString stringWithUTF8String:signStr];
    }
    return nil;

}

/// 验证签名
+ (BOOL)verfiySign:(NSString *)sign signedData:(NSString *)signedData pubkey:(NSString *)pubkey {
    if (!pubkey || !sign || !signedData) {
        return NO;
    }
    char *publicKey_ = (char *) [pubkey UTF8String];
    char *signData_ = (char *) [sign UTF8String];
    char *hashstr_ = (char *) [signedData UTF8String];
    int result = VerifySign_im(publicKey_, hashstr_, signData_);
    if (result == 1) {
        return YES;
    }
    return NO;
}


/// 加密数据
+ (LMEncryptGcmData *)encodeAES_GCMWithECDHKey:(NSData *)ECDHKey data:(NSData *)data aad:(NSData *)aad {
    if (!data || data.length <= 0 || !ECDHKey || ECDHKey.length <= 0 || !aad || aad.length <= 0) {
        return nil;
    }
    unsigned char *encryptedData;
    NSData *ivData = [self createRandom512bits];
    ivData = [ivData subdataWithRange:NSMakeRange(0, 16)];
    //IV
    unsigned char *ivdata = (unsigned char *) [ivData bytes];
    // key
    unsigned char *keydata = (unsigned char *) [ECDHKey bytes];
    //aad
    unsigned char *aaddata = (unsigned char *) [aad bytes];
    // perapre indata
    unsigned char *indata = (unsigned char *) [data bytes];
    //接受tag
    unsigned char tag[16];
    int encryptedLen = xtalkEncodeAES_gcm_im(indata, (int)data.length, aaddata, (int)aad.length, keydata, ivdata, (int)ivData.length, &encryptedData, tag);
    if (encryptedLen == -1) {
        return nil;
    }
    NSData *ciphertextData = [NSData dataWithBytes:(const void *) encryptedData length:sizeof(unsigned char) * encryptedLen];
    NSData *tagData = [NSData dataWithBytes:(const void *) tag length:sizeof(unsigned char) * 16];

    LMEncryptGcmData *encryGcm = [LMEncryptGcmData new];
    encryGcm.iv = ivData;
    encryGcm.aad = aad;
    encryGcm.ciphertext = ciphertextData;
    encryGcm.tag = tagData;

    if (encryptedData)
        free(encryptedData);
    return encryGcm;
}

/// 解密数据
+ (NSData *)decodeAES_GCMDataWithECDHKey:(NSData *)ECDHKey data:(NSData *)data aad:(NSData *)aad iv:(NSData *)iv tag:(NSData *)tag {
    unsigned char *decryptedData;
    unsigned char *IVByte = (unsigned char *) [iv bytes];
    unsigned char *KeyByte = (unsigned char *) [ECDHKey bytes];
    unsigned char *inDataByte = (unsigned char *) [data bytes];
    unsigned char *aadByte = (unsigned char *) [aad bytes];
    unsigned char *tagByte = (unsigned char *) [tag bytes];
    int decryptedLen = xtalkDecodeAES_gcm_im(inDataByte, (int)data.length, aadByte, (int)aad.length, tagByte, KeyByte, IVByte, (int)iv.length, &decryptedData);
    NSData *result = nil;
    if (decryptedLen > 0) {
        result = [[NSData alloc] initWithBytes:&decryptedData[0] length:decryptedLen];
    } else {
        std::string error = xtalk_getErrInfo_im();
        printf("Error: %s\n", error.c_str());
    }
    if (decryptedData)
        free(decryptedData);
    return result;
}


+ (NSData *)getAes256KeyByECDHKeyAndSalt:(NSData *)ecdhKey salt:(NSData *)salt {
    const char *ecdhKey_c = (const char *) ecdhKey.bytes;
    const char *salt_c;
    if (!salt || salt.length != 64) {
        char default_salt[64];
        memset(default_salt, 0x00, 64);
        salt_c = &default_salt[0];
    } else {
        salt_c = (const char *) salt.bytes;
    }
    unsigned char outKey[256 / 8];
    xtalkPBKDF2_HMAC_SHA512_im((unsigned char *) ecdhKey_c, (int) ecdhKey.length, (unsigned char *) salt_c, 512, outKey, 256, 12);
    NSData *data = [NSData dataWithBytes:outKey length:32];
    return data;
}

+ (NSData *)getECDHkeyWithPrivkey:(NSString *)privkey publicKey:(NSString *)pubkey {
    char *privkeyc = (char *) [privkey UTF8String];
    char *pubkeyc = (char *) [pubkey UTF8String];
    unsigned char ecdh_key[32];
    int len = xtalk_getRawECDHkey_im(privkeyc, pubkeyc, ecdh_key);
    if (len == 32) {
        NSData *ecdhData = [NSData dataWithBytes:(const void *) ecdh_key length:sizeof(unsigned char) * 32];
        return ecdhData;
    }
    return nil;
}


///---------------底层方法------------------

char *ossl_err_as_string_im(void) {
    BIO *bio = BIO_new(BIO_s_mem());
    ERR_print_errors(bio);
    char *buf = NULL;
    size_t len = BIO_get_mem_data (bio, &buf);
    char *ret = (char *) calloc(1, 1 + len);
    if (ret)
        memcpy(ret, buf, len);
    BIO_free(bio);
    return ret;
}

std::string xtalk_getErrInfo_im() {
    char *perror = ossl_err_as_string_im();
    std::string err = perror;
    free(perror);
    return err;
}


+ (NSData *)createRandom512bits {
    uint8_t randNum[512 / 8];
    xtalkRNG_im(randNum, 512);
    return [NSData dataWithBytes:randNum length:512 / 8];
}

/**
 *  IOS side through openssl get the specified bit length random number
 */
void RNG_openssl_im(unsigned char *buf, int bits) {
    RAND_bytes(buf, bits / 8);
}

/**
 *  The IOS side obtains a random number of the specified bit length through the ios system call
 */
void RNG_ios_im(unsigned char *buf, int bits) {
    int result = SecRandomCopyBytes(kSecRandomDefault, bits / 8, buf);
    if (result == 0) {
        
    }
}

/**
 *  XOR two data blocks of the same bit length, writing the result to another data block
 */
void XORbits_im(const void *buf1, const void *buf2, int bits, void *res) {
    for (int i = 0; i < bits / 8; ++i) {
        ((uint8_t *) res)[i] = ((uint8_t *) buf1)[i] ^ ((uint8_t *) buf2)[i];
    }
}


/**
 *  The APP side generates a random number of cryptographic security
 */
void xtalkRNG_im(void *buf, int bits) {
    // get randnum by openssl
    uint8_t fromOpenssl[bits / 8];
    RNG_openssl_im(fromOpenssl, bits);
    // get randnum by ios
    uint8_t fromIOS[bits / 8];
    RNG_ios_im(fromIOS, bits);
    // mix(xor) two randnum into buf
    XORbits_im(fromOpenssl, fromIOS, bits, buf);
}



int SignHash_im(char *privKey, char *hashHexStr, char *signStr) {
    CBitcoinSecret btcSecret;
    if (!btcSecret.SetString(privKey)) {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return 1;
    }
    CKey key = btcSecret.GetKey();
    uint256 hashMsg;
    hashMsg.SetHex(hashHexStr);
    
    // normal signatures
    vector<unsigned char> sign;
    if (!key.Sign(hashMsg, sign)) {
        printf("Error : key1.Sign (hashMsg, sign1)\n");
        return 2;
    }
    
    string signstring = HexStr(sign.begin(), sign.end());
    sprintf(signStr, "%s", signstring.c_str());
    return 0;
}


int VerifySign_im(char *pubKey, char *hashHexStr, char *signStr) {
    uint256 hashMsg;
    hashMsg.SetHex(hashHexStr);
    std::vector<unsigned char> sign = ParseHex(signStr);
    std::string pubkeyStr = pubKey;
    CPubKey pubkey(ParseHex(pubkeyStr));
    if (!pubkey.Verify(hashMsg, sign)) {
        printf("Error : pubkey1.Verify(hashMsg, sign1C)\n");
        return 0;
    }
    return 1;
}


int xtalkEncodeAES_gcm_im(unsigned char *plaintext, int plaintext_len, unsigned char *aad,
                          int aad_len, unsigned char *key, unsigned char *iv, int ivlen,
                          unsigned char **cipherret, unsigned char *tag) {
    EVP_CIPHER_CTX *ctx;
    
    int len;
    unsigned char *ciphertext;
    int ciphertext_len;
    
    unsigned char initval_hex[16] = {0x23, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x33};
    
    if ((!iv) || ivlen <= 0) {
        iv = initval_hex;
        ivlen = 16;
    }
    
    *cipherret = (unsigned char *) malloc(plaintext_len);
    ciphertext = *cipherret;
    
    /* Create and initialise the context */
    if (!(ctx = EVP_CIPHER_CTX_new())) {
        printf("EVP_CIPHER_CTX_new error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }
    
    /* Initialise the encryption operation. */
    if (1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL)) {
        printf("EVP_EncryptInit_ex error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }
    
    /* Set IV length if default 12 bytes (96 bits) is not appropriate */
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, ivlen, NULL)) {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }
    
    /* Initialise key and IV */
    if (1 != EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv)) {
        printf("EVP_EncryptInit_ex error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }
    
    /* Provide any AAD data. This can be called zero or more times as
     * required
     */
    if (1 != EVP_EncryptUpdate(ctx, NULL, &len, aad, aad_len)) {
        printf("EVP_EncryptUpdate error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }
    
    /* Provide the message to be encrypted, and obtain the encrypted output.
     * EVP_EncryptUpdate can be called multiple times if necessary
     */
    if (1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len)) {
        printf("EVP_EncryptUpdate error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }
    ciphertext_len = len;
    
    /* Finalise the encryption. Normally ciphertext bytes may be written at
     * this stage, but this does not occur in GCM mode
     */
    if (1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len)) {
        printf("EVP_EncryptFinal_ex error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }
    ciphertext_len += len;
    
    /* Get the tag */
    if (1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tag)) {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(ciphertext);
        *cipherret = NULL;
        return -1;
    }
    
    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);
    
    return ciphertext_len;
}

int xtalkDecodeAES_gcm_im(unsigned char *ciphertext, int ciphertext_len, unsigned char *aad,
                          int aad_len, unsigned char *tag, unsigned char *key, unsigned char *iv, int ivlen,
                          unsigned char **plainret) {
    EVP_CIPHER_CTX *ctx;
    int len;
    unsigned char *plaintext;
    int plaintext_len;
    int ret;
    
    unsigned char initval_hex[16] = {0x23, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x33};
    
    if ((!iv) || ivlen <= 0) {
        iv = initval_hex;
        ivlen = 16;
    }
    
    *plainret = (unsigned char *) malloc(ciphertext_len);
    plaintext = *plainret;
    
    /* Create and initialise the context */
    if (!(ctx = EVP_CIPHER_CTX_new())) {
        printf("EVP_CIPHER_CTX_new error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }
    
    /* Initialise the decryption operation. */
    if (!EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL)) {
        printf("EVP_DecryptInit_ex error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }
    
    /* Set IV length. Not necessary if this is 12 bytes (96 bits) */
    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, ivlen, NULL)) {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }
    
    /* Initialise key and IV */
    if (!EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv)) {
        printf("EVP_DecryptInit_ex error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }
    
    /* Provide any AAD data. This can be called zero or more times as
     * required
     */
    if (!EVP_DecryptUpdate(ctx, NULL, &len, aad, aad_len)) {
        printf("EVP_DecryptUpdate error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }
    
    /* Provide the message to be decrypted, and obtain the plaintext output.
     * EVP_DecryptUpdate can be called multiple times if necessary
     */
    if (!EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len)) {
        printf("EVP_DecryptUpdate error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }
    plaintext_len = len;
    
    /* Set expected tag value. Works in OpenSSL 1.0.1d and later */
    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, tag)) {
        printf("EVP_CIPHER_CTX_ctrl error!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }
    
    /* Finalise the decryption. A positive return value indicates success,
     * anything else is a failure - the plaintext is not trustworthy.
     */
    ret = EVP_DecryptFinal_ex(ctx, plaintext + len, &len);
    
    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);
    
    if (ret > 0) {
        /* Success */
        plaintext_len += len;
        return plaintext_len;
    } else {
        /* Verify failed */
        printf("GCM Verify failed!\n");
        free(plaintext);
        *plainret = NULL;
        return -1;
    }
}


int xtalk_getRawECDHkey_im(char *privKey, char *pubKey, unsigned char *ecdh_key) {
    char rawPrivKey[256];
    GetRawPrivKey_im(rawPrivKey, privKey);
    return ecies_getRawECDHkey(rawPrivKey, pubKey, ecdh_key);    // return real length of raw ecdh_key;
}

int GetRawPrivKey_im(char *rawPrivKey, char *privKey) {
    string privStr(privKey);
    CBitcoinSecret btcSecret;
    if (!btcSecret.SetString(privStr)) {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return 1;
    }
    CKey pkey = btcSecret.GetKey();
    std::vector<unsigned char> vch(pkey.begin(), pkey.end());
    std::string pkeyStr = HexStr(vch);
    
    sprintf(rawPrivKey, "%s", pkeyStr.c_str());
    //    printf("rawPrivKey is :%s\n",rawPrivKey);
    return 0;
}

void xtalkPBKDF2_HMAC_SHA512_im(unsigned char *pass, int passLen, unsigned char *salt, int saltLen, uint8_t *key, int keyLen, int n) {
    // calc iteration count 2^n
    uint32_t iter = 1 << n;
    PKCS5_PBKDF2_HMAC((const char *) pass, passLen, salt, saltLen / 8, iter, EVP_sha512(), keyLen / 8, key);
}


int CreateNewPrivKey_im(char *privKey) {
    CKey key;
    key.MakeNewKey(true); // set rand bytes. we need add our own MakeNewKey(true, randombytes_data), we need use our own RAND_bytes func to get random bytes.
    CBitcoinSecret btcSecret(key);
    //        sprintf(privKey,"%s",btcSecret.begin());
    sprintf(privKey, "%s", btcSecret.ToString().c_str());
    
    return 0;
}

int GetPubKeyFromPrivKey_im(char *privKey, char *pubKey) {
    string privStr(privKey);
    CBitcoinSecret btcSecret;
    if (!btcSecret.SetString(privStr)) {
        printf("Error : btcSecret.SetString (privStr)...\n");
        return 1;
    }
    CPubKey pubkey = btcSecret.GetKey().GetPubKey();
    std::vector<unsigned char> vch(pubkey.begin(), pubkey.end());
    std::string pubkeyStr = HexStr(vch);
    
    sprintf(pubKey, "%s", pubkeyStr.c_str());
    
    return 0;
}


@end
