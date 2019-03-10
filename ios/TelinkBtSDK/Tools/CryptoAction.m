/********************************************************************************************************
 * @file     CryptoAction.m 
 *
 * @brief    for TLSR chips
 *
 * @author	 telink
 * @date     Sep. 30, 2010
 *
 * @par      Copyright (c) 2010, Telink Semiconductor (Shanghai) Co., Ltd.
 *           All rights reserved.
 *           
 *			 The information contained herein is confidential and proprietary property of Telink 
 * 		     Semiconductor (Shanghai) Co., Ltd. and is available under the terms 
 *			 of Commercial License Agreement between Telink Semiconductor (Shanghai) 
 *			 Co., Ltd. and the licensee in separate contract or the terms described here-in. 
 *           This heading MUST NOT be removed from this file.
 *
 * 			 Licensees are granted free, non-transferable use of the information in this 
 *			 file under Mutual Non-Disclosure Agreement. NO WARRENTY of ANY KIND is provided. 
 *           
 *******************************************************************************************************/
//
//  CryptoAction.m
//  TelinkBlue
//
//  Created by Green on 11/15/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#import "CryptoAction.h"
#include "CryptoUtil.h"

#define random(x) (rand()%x)

@implementation CryptoAction

+(BOOL)getRandPro:(uint8_t *)prand Len:(int)len
{
    srand((int)time(0));
    memset(prand, 0, len);
    for (int i=0;i<len;i++)
        prand[i]=(uint8_t)random(255);
    
    return YES;
}

+(BOOL)encryptPair:(NSString *)uName Pas:(NSString *)uPas Prand:(uint8_t *)prand PResult:(uint8_t *)presult
{
    unsigned char *tmpNetworkName=(unsigned char *)[uName cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char *tmpPassword=(unsigned char *)[uPas cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char		pNetworkName[16];
    unsigned char		pPassword[16];
    
    memset(pNetworkName, 0, 16);
    memset(pPassword, 0, 16);
    
    memcpy(pNetworkName, tmpNetworkName, strlen((char *)tmpNetworkName));
    memcpy(pPassword, tmpPassword, strlen((char *)tmpPassword));
    
    unsigned char sk[16], d[16], r[16];
    int i;
    for (i=0; i<16; i++)
    {
        d[i] = pNetworkName[i] ^ pPassword[i];
    }
    memcpy (sk, prand, 8);
    memset (sk + 8, 0, 8);
    aes_att_encryption (sk, d, r);
    memcpy (presult, prand, 8);
    memcpy (presult+8, r, 8);
    
    if (!(memcmp (prand, presult, 16)))
        return YES;
    
    return NO;
}

+(BOOL)getSectionKey:(NSString *)uName Pas:(NSString *)uPas Prandm:(uint8_t *)prandm Prands:(uint8_t *)prands PResult:(uint8_t *)presult
{
    unsigned char *tmpNetworkName=(unsigned char *)[uName cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char *tmpPassword=(unsigned char *)[uPas cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char		pNetworkName[16];
    unsigned char		pPassword[16];
    
    memset(pNetworkName, 0, 16);
    memset(pPassword, 0, 16);
    
    memcpy(pNetworkName, tmpNetworkName, strlen((char *)tmpNetworkName));
    memcpy(pPassword, tmpPassword, strlen((char *)tmpPassword));
    
    unsigned char sk[16], d[16], r[16];
    int i;
    for (i=0; i<16; i++)
    {
        d[i] = pNetworkName[i] ^ pPassword[i];
    }
    memcpy (sk, prandm, 8);
    memcpy (sk + 8, prands, 8);
    aes_att_encryption (d, sk, r);
    memcpy (presult, r, 16);
    
    return YES;
}


+(BOOL)encryptionPpacket:(uint8_t *)key Iv:(uint8_t *)iv Mic:(uint8_t *)mic MicLen:(int)mic_len Ps:(uint8_t *)ps Len:(int)len
{
    uint8_t	e[16], r[16], i;
    ///////////// calculate mic ///////////////////////
    memset (r, 0, 16);
    memcpy (r, iv, 8);
    r[8] = len;
    aes_att_encryption (key, r, r);
        for (i=0; i<len; i++)
    {
        r[i & 15] ^= ps[i];
        
        if ((i&15) == 15 || i == len - 1)
        {
            aes_att_encryption (key, r, r);
        }
    }
    for (i=0; i<mic_len; i++)
    {
        mic[i] = r[i];
    }
    ///////////////// calculate enc ////////////////////////
    memset (r, 0, 16);
    memcpy (r+1, iv, 8);
    for (i=0; i<len; i++)
    {
        if ((i&15) == 0)
        {
            aes_att_encryption (key, r, e);
            r[0]++;
        }
        ps[i] ^= e[i & 15];
    }
    return YES;
}


+(BOOL)decryptionPpacket:(uint8_t *)key Iv:(uint8_t *)iv Mic:(uint8_t *)mic MicLen:(int)mic_len Ps:(uint8_t *)ps Len:(int)len
{
    uint8_t	e[16], r[16], i;
    
    ///////////////// calculate enc ////////////////////////
    memset (r, 0, 16);
    memcpy (r+1, iv, 8);
    for (i=0; i<len; i++)
    {
        if ((i&15) == 0)
        {
            aes_att_encryption (key, r, e);
            r[0]++;
        }
        ps[i] ^= e[i & 15];
    }
    
    ///////////// calculate mic ///////////////////////
    memset (r, 0, 16);
    memcpy (r, iv, 8);
    r[8] = len;
    aes_att_encryption (key, r, r);
    
    for (i=0; i<len; i++)
    {
        r[i & 15] ^= ps[i];
        
        if ((i&15) == 15 || i == len - 1)
        {
            aes_att_encryption (key, r, r);
        }
    }
    
    for (i=0; i<mic_len; i++)
    {
        if (mic[i] != r[i])
        {
            return NO;			//Failed
        }
    }
    return YES;
}


+(BOOL)getNetworkInfo:(uint8_t *)pcmd Opcode:(int)opcode Str:(NSString *)str Psk:(uint8_t *)psk
{
    unsigned char *tmpNetworkName=(unsigned char *)[str cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char		pNetworkName[16];
    
    memset(pNetworkName, 0, 16);
    
    memcpy(pNetworkName, tmpNetworkName, strlen((char *)tmpNetworkName));
    
    pcmd[0] = opcode;
    aes_att_encryption (psk, pNetworkName, pcmd + 1);
    return YES;
}


+(BOOL)getNetworkInfoByte:(uint8_t *)pcmd Opcode:(int)opcode Str:(uint8_t *)str Psk:(uint8_t *)psk
{
    pcmd[0] = opcode;
    aes_att_encryption (psk, str, pcmd + 1);
    return 17;
}

@end
