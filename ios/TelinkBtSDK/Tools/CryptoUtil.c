/********************************************************************************************************
 * @file     CryptoUtil.c 
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
//  CryptoUtil.c
//  TelinkBlue
//
//  Created by Green on 11/15/15.
//  Copyright (c) 2015 Green. All rights reserved.
//

#include "CryptoUtil.h"
#include <string.h>
typedef unsigned char u8;
typedef unsigned char           word8;
typedef unsigned short          word16;
typedef unsigned long           word32;

static const word8 aes_sw_S[256] = {
    99, 124, 119, 123, 242, 107, 111, 197,  48,   1, 103,  43, 254, 215, 171, 118,
    202, 130, 201, 125, 250,  89,  71, 240, 173, 212, 162, 175, 156, 164, 114, 192,
    183, 253, 147,  38,  54,  63, 247, 204,  52, 165, 229, 241, 113, 216,  49,  21,
    4, 199,  35, 195,  24, 150,   5, 154,   7,  18, 128, 226, 235,  39, 178, 117,
    9, 131,  44,  26,  27, 110,  90, 160,  82,  59, 214, 179,  41, 227,  47, 132,
    83, 209,   0, 237,  32, 252, 177,  91, 106, 203, 190,  57,  74,  76,  88, 207,
    208, 239, 170, 251,  67,  77,  51, 133,  69, 249,   2, 127,  80,  60, 159, 168,
    81, 163,  64, 143, 146, 157,  56, 245, 188, 182, 218,  33,  16, 255, 243, 210,
    205,  12,  19, 236,  95, 151,  68,  23, 196, 167, 126,  61, 100,  93,  25, 115,
    96, 129,  79, 220,  34,  42, 144, 136,  70, 238, 184,  20, 222,  94,  11, 219,
    224,  50,  58,  10,  73,   6,  36,  92, 194, 211, 172,  98, 145, 149, 228, 121,
    231, 200,  55, 109, 141, 213,  78, 169, 108,  86, 244, 234, 101, 122, 174,   8,
    186, 120,  37,  46,  28, 166, 180, 198, 232, 221, 116,  31,  75, 189, 139, 138,
    112,  62, 181, 102,  72,   3, 246,  14,  97,  53,  87, 185, 134, 193,  29, 158,
    225, 248, 152,  17, 105, 217, 142, 148, 155,  30, 135, 233, 206,  85,  40, 223,
    140, 161, 137,  13, 191, 230,  66, 104,  65, 153,  45,  15, 176,  84, 187,  22,
};
static const word8 aes_sw_Si[256] = {
    82,   9, 106, 213,  48,  54, 165,  56, 191,  64, 163, 158, 129, 243, 215, 251,
    124, 227,  57, 130, 155,  47, 255, 135,  52, 142,  67,  68, 196, 222, 233, 203,
    84, 123, 148,  50, 166, 194,  35,  61, 238,  76, 149,  11,  66, 250, 195,  78,
    8,  46, 161, 102,  40, 217,  36, 178, 118,  91, 162,  73, 109, 139, 209,  37,
    114, 248, 246, 100, 134, 104, 152,  22, 212, 164,  92, 204,  93, 101, 182, 146,
    108, 112,  72,  80, 253, 237, 185, 218,  94,  21,  70,  87, 167, 141, 157, 132,
    144, 216, 171,   0, 140, 188, 211,  10, 247, 228,  88,   5, 184, 179,  69,   6,
    208,  44,  30, 143, 202,  63,  15,   2, 193, 175, 189,   3,   1,  19, 138, 107,
    58, 145,  17,  65,  79, 103, 220, 234, 151, 242, 207, 206, 240, 180, 230, 115,
    150, 172, 116,  34, 231, 173,  53, 133, 226, 249,  55, 232,  28, 117, 223, 110,
    71, 241,  26, 113,  29,  41, 197, 137, 111, 183,  98,  14, 170,  24, 190,  27,
    252,  86,  62,  75, 198, 210, 121,  32, 154, 219, 192, 254, 120, 205,  90, 244,
    31, 221, 168,  51, 136,   7, 199,  49, 177,  18,  16,  89,  39, 128, 236,  95,
    96,  81, 127, 169,  25, 181,  74,  13,  45, 229, 122, 159, 147, 201, 156, 239,
    160, 224,  59,  77, 174,  42, 245, 176, 200, 235, 187,  60, 131,  83, 153,  97,
    23,  43,   4, 126, 186, 119, 214,  38, 225, 105,  20,  99,  85,  33,  12, 125,
};
static const word8 aes_sw_rcon[30] = {
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80,
    0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f,
    0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 
    0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91
};
static signed char	aes_sw_rconptr;
static signed char  aes_sw_mode = 0;
static word8	aes_sw_k0[4][4];
static word8	aes_sw_k10[4][4];
static word8	aes_sw_ktmp[4][4];
static void aes_sw_nextkey(unsigned char *a, int dir) {
    int i, j;
    if(dir == 0) {
        for(i = 0; i < 4; i++)
            a[i * 4 + 0] ^= aes_sw_S[a[((i+1)&3) * 4 + 3]];
        a[0] ^= aes_sw_rcon[aes_sw_rconptr++];
        for(j = 1; j < 4; j++)
            for(i = 0; i < 4; i++) a[i * 4 + j] ^= a[i * 4 + j-1];
    }
    else {
        for(j = 3; j > 0; j--)
            for(i = 0; i < 4; i++) a[i * 4 + j] ^= a[i * 4 + j-1];
        a[0] ^= aes_sw_rcon[aes_sw_rconptr--];
        for(i = 0; i < 4; i++)
            a[i * 4 + 0] ^= aes_sw_S[a[((i+1)&3) * 4 + 3]];
    }
}

void _rijndaelSetKey (unsigned char *k)
{
    int i, j, l;
    for(j = 0; j < 4; j++)
        for(i = 0; i < 4; i++) {
            aes_sw_k0[i][j] = k[j*4 + i];
            aes_sw_k10[i][j] = k[j*4 + i];
        }
    aes_sw_rconptr = 0;
    for(l = 0; l < 10; l ++)
        aes_sw_nextkey(aes_sw_k10[0], 0);
}

static void aes_sw_KeyAddition(unsigned char * a, unsigned char *k) {
    int i;
    for(i = 0; i < 16; i++)
        a[i] ^= k[i];
}

static void aes_sw_Substitution(unsigned char * a) {
    int i;
    for(i = 0; i < 16; i++) a[i] = (aes_sw_mode == 0)?aes_sw_S[a[i]]:aes_sw_Si[a[i]];
}

static void aes_sw_ShiftRow(unsigned char *a) {
    int i, j;
    for(i = 1; i < 4; i++) {
        for(j = 0; j < 4; j++) {
            word8 tmp[2];
            int s = (aes_sw_mode == 0)?i:(4-i);
            int v = (s + j) >> 2;
            int _j = (s + j) & 3;
            if(j == 0 || (j == 2 && s == 3))
                tmp[0] = a[i * 4 + j];
            if(j == 1)
                tmp[1] = a[i * 4 + j];
            a[i * 4 + j] = v?tmp[_j & 1]:a[i * 4 + _j];
        }
    }
}

static word8 aes_sw_mul(word8 a, word8 b) {
    word8 x0, x1, x2, x3, x4, x5, x6, x7;
    x0 = a;
    x1 = (x0 & 0x80)?((x0 << 1) ^ 0x1b) : (x0 << 1);
    x2 = (x1 & 0x80)?((x1 << 1) ^ 0x1b) : (x1 << 1);
    x3 = (x2 & 0x80)?((x2 << 1) ^ 0x1b) : (x2 << 1);
    x4 = (x3 & 0x80)?((x3 << 1) ^ 0x1b) : (x3 << 1);
    x5 = (x4 & 0x80)?((x4 << 1) ^ 0x1b) : (x4 << 1);
    x6 = (x5 & 0x80)?((x5 << 1) ^ 0x1b) : (x5 << 1);
    x7 = (x6 & 0x80)?((x6 << 1) ^ 0x1b) : (x6 << 1);
    return ((b & 0x80)?x7:0) ^ ((b & 0x40)?x6:0) ^
    ((b & 0x20)?x5:0) ^ ((b & 0x10)?x4:0) ^
    ((b & 0x08)?x3:0) ^ ((b & 0x04)?x2:0) ^
    ((b & 0x02)?x1:0) ^ ((b & 0x01)?x0:0);
}

static void aes_sw_MixColumn(unsigned char *a) {
    unsigned char b[16];
    int i, j;
    
    for(j = 0; j < 4; j++)
    {
        for(i = 0; i < 4; i++)
        {
            b[i * 4 + j] = aes_sw_mul((aes_sw_mode == 0)?2:0xe, a[i * 4 + j])
            ^ aes_sw_mul((aes_sw_mode == 0)?3:0xb, a[((i + 1) & 3) * 4 + j])
            ^ aes_sw_mul((aes_sw_mode == 0)?1:0xd, a[((i + 2) & 3) * 4 + j])
            ^ aes_sw_mul((aes_sw_mode == 0)?1:0x9, a[((i + 3) & 3) * 4 + j]);
        }
    }
    for(i = 0; i < 16; i++)
        a[i] = b[i];
}

void aes_sw_SwapRowCol (unsigned char * a)
{
    int i;
    int j;
    unsigned char t;
    for (i=0; i<4; i++)
        for (j=i+1; j<4; j++)
        {
            t = a[i * 4 + j];
            a[i * 4 + j] = a[j * 4 + i];
            a[j * 4 + i] = t;
        }
}


void _rijndaelEncrypt(unsigned char *a)
{
    int i, r;
    unsigned char *pt, *pk;
    aes_sw_mode = 0;
    aes_sw_SwapRowCol (a);
    
    pt = aes_sw_ktmp[0];
    pk = aes_sw_k0[0];
    for (i=0; i<16; i++)
    {
        pt[i] = pk[i];
    }
    
    aes_sw_rconptr = 0;
    
    for(r = 0; r < 11; r++) {
        if(r != 0) {
            aes_sw_Substitution(a);
        }
        
        if(r != 0) {
            aes_sw_ShiftRow(a);
        }
        
        if(r != 0 && r != 10) {
            aes_sw_MixColumn(a);
        }
        
        aes_sw_KeyAddition(a, aes_sw_ktmp[0]);
        
        aes_sw_nextkey(aes_sw_ktmp[0], 0);
    }
    
    aes_sw_SwapRowCol (a);
}

void _rijndaelDecrypt (unsigned char *a)
{
    int i, r;
    unsigned char *pt, *pk;
    
    aes_sw_mode = 1;
    
    aes_sw_SwapRowCol (a);
    
    pt = aes_sw_ktmp[0];
    pk = aes_sw_k10[0];
    for (i=0; i<16; i++)
    {
        pt[i] = pk[i];
    }
    
    aes_sw_rconptr = 9;
    
    for(r = 0; r < 11; r++) {
        aes_sw_KeyAddition(a,aes_sw_ktmp[0]);
        if(r != 0 && r != 10) {
            aes_sw_MixColumn(a);
        }
        if(r != 10) {
            aes_sw_Substitution(a);
        }
        if(r != 10) {
            aes_sw_ShiftRow(a);
        }
        
        aes_sw_nextkey(aes_sw_ktmp[0], 1);
    }
    aes_sw_SwapRowCol (a);
}


void aes_att_swap (u8 *k)
{
    int i;
    for (i=0; i<8; i++)
    {
        u8 t = k[i];
        k[i] = k[15 - i];
        k[15 - i] = t;
    }
}

int		att_crypto_poly = 0;
void aes_att_encryption_poly (u8 *pk, u8 *pd, u8 *pr)        //
{
    unsigned char r[16];
    static unsigned short poly[2]={0, 0xa001};              //0x8005 <==> 0xa001
    unsigned short crc = 0xffff;
    unsigned char t = 0;
    int i,j;
    for(j=0; j<16; j++)
    {
        unsigned char ds = pk[j];
        for(i=0; i<8; i++)
        {
            crc = (crc >> 1) ^ poly[(crc ^ ds ) & 1];
            ds = ds >> 1;
        }
        t ^= crc ^ pd[j];
        r[15-j] = t;
    }
    memcpy (pr, r, 16);
}

void aes_att_decryption_poly (u8 *pk, u8 *pd, u8 *pr)
{
    unsigned char r[16];
    static unsigned short poly[2]={0, 0xa001};              //0x8005 <==> 0xa001
    unsigned short crc = 0xffff;
    unsigned char t = 0;
    int i,j;
    
    for(j=0; j<16; j++)
    {
        unsigned char ds = pk[j];
        for(i=0; i<8; i++)
        {
            crc = (crc >> 1) ^ poly[(crc ^ ds ) & 1];
            ds = ds >> 1;
        }
        //t ^= crc ^ pd[15 - j];
        r[j] = t ^ crc ^ pd[15 - j];
        t ^= crc ^ r[j];
    }
    memcpy (pr, r, 16);
}

void aes_att_encryption(u8 *key, u8 *plaintext, u8 *result)
{
    u8 sk[16];
    int i;
    
    if (att_crypto_poly)
    {
        aes_att_encryption_poly (key, plaintext, result);
        return;
    }
    
    aes_sw_mode = 0;
    for (i=0; i<16; i++)
    {
        sk[i] = key[15 - i];
    }
    _rijndaelSetKey (sk);
    
    for (i=0; i<16; i++)
    {
        sk[i] = plaintext[15 - i];
    }
    _rijndaelEncrypt (sk);
    
    memcpy (result, sk, 16);
    
    aes_att_swap (result);
}

void aes_att_decryption(u8 *key, u8 *plaintext, u8 *result)
{
    u8 sk[16];
    int i;
    
    if (att_crypto_poly)
    {
        aes_att_decryption_poly (key, plaintext, result);
        return;
    }
    aes_sw_mode = 1;
    for (i=0; i<16; i++)
    {
        sk[i] = key[15 - i];
    }
    _rijndaelSetKey (sk);
    
    for (i=0; i<16; i++)
    {
        sk[i] = plaintext[15 - i];
    }
    _rijndaelDecrypt (sk);
    memcpy (result, sk, 16);
    aes_att_swap (result);
}


int	aes_att_er (unsigned char *pNetworkName, unsigned char *pPassword, unsigned char *prand, unsigned char *presult)
{
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
    
    return !(memcmp (prand, presult, 16));
}
